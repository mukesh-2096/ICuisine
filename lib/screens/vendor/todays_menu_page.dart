import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_menu_item_page.dart';

class TodaysMenuPage extends StatefulWidget {
  const TodaysMenuPage({super.key});

  @override
  State<TodaysMenuPage> createState() => _TodaysMenuPageState();
}

class _TodaysMenuPageState extends State<TodaysMenuPage> {
  // Use map to store local state to avoid losing state when adding new items or filtering
  final Set<String> _selectedItemIds = {};
  final Set<String> _todaySpecialIds = {};
  // New Sets to track initial state for comparison
  final Set<String> _initialSelectedItemIds = {};
  final Set<String> _initialTodaySpecialIds = {};
  
  bool _isLoading = false;
  bool _isInit = true;
  bool _viewingLive = true; // Start in Live View mode
  bool _hasChanges = false; // Track if there are unsaved changes

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final subtextColor2 = isDark ? Colors.white60 : Colors.black54;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white10 : Colors.grey[300]!;
    final iconColor = isDark ? Colors.white24 : Colors.grey;

    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: Text('Please login to manage menu', style: GoogleFonts.outfit(color: subtextColor))),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _viewingLive ? "Live Menu Preview" : "Manage Today's Menu",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(_viewingLive ? Icons.edit : Icons.close, color: const Color(0xFFFA5211)),
            onPressed: () {
               if (_viewingLive) {
                 setState(() => _viewingLive = false);
               } else {
                 // Discard changes and revert to live view
                 setState(() {
                   _selectedItemIds.clear();
                   _selectedItemIds.addAll(_initialSelectedItemIds);
                   _todaySpecialIds.clear();
                   _todaySpecialIds.addAll(_initialTodaySpecialIds);
                   _viewingLive = true;
                   _hasChanges = false;
                 });
               }
            },
          ),
          if (!_viewingLive)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFFFA5211)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddMenuItemPage()),
                ).then((_) {
                  // After adding an item, force refresh to see new item
                  if (mounted) {
                    setState(() {
                      // We don't necessarily need to exit edit mode, just refresh list
                      // But effectively we are already in edit mode (viewingLive = false)
                      _isInit = true; // Trigger re-fetch of initial state including new item
                    });
                  }
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_viewingLive)
             Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You are currently LIVE with ${_selectedItemIds.length} items visible to customers.",
                        style: GoogleFonts.outfit(color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: backgroundColor,
              child: Text(
                "Check items to make them LIVE. Tap star for Today's Special.",
                style: GoogleFonts.outfit(color: subtextColor2, fontSize: 13),
              ),
            ),
            
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vendors')
                  .doc(user.uid)
                  .collection('menu')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No menu items found.', style: GoogleFonts.outfit(color: hintColor)),
                        const SizedBox(height: 10),
                        TextButton(
                           onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddMenuItemPage()),
                            );
                          },
                          child: Text('Add Items', style: GoogleFonts.outfit(color: const Color(0xFFFA5211))),
                        )
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                // Initialize selection on first load based on existing data
                if (_isInit) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedItemIds.clear();
                      _todaySpecialIds.clear();
                      _initialSelectedItemIds.clear();
                      _initialTodaySpecialIds.clear();

                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['isAvailable'] == true) {
                          _selectedItemIds.add(doc.id);
                          _initialSelectedItemIds.add(doc.id);
                        }
                        if (data['isTodaySpecial'] == true) {
                          _todaySpecialIds.add(doc.id);
                          _initialTodaySpecialIds.add(doc.id);
                        }
                      }
                      _isInit = false;

                      // Self-healing: Ensure vendor document has correct status
                      FirebaseFirestore.instance
                          .collection('vendors')
                          .doc(user.uid)
                          .update({'hasLiveItems': _selectedItemIds.isNotEmpty})
                          .catchError((e) => print("Error syncing live status: $e"));
                    });
                  });
                }
                
                // Filter for "Live View" mode
                final displayDocs = _viewingLive 
                    ? docs.where((doc) => _selectedItemIds.contains(doc.id)).toList()
                    : docs;

                if (displayDocs.isEmpty && _viewingLive) {
                  return Center(child: Text('No items are currently live.', style: GoogleFonts.outfit(color: hintColor)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayDocs.length,
                  itemBuilder: (context, index) {
                    final doc = displayDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // In viewing Live mode, use read-only state. In edit mode, use interactive state.
                    final isSelected = _selectedItemIds.contains(doc.id);
                    final isSpecial = _todaySpecialIds.contains(doc.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFA5211).withOpacity(0.5) : borderColor,
                        ),
                      ),
                      child: ListTile(
                        leading: _viewingLive 
                          ? Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                              child: const Icon(Icons.check, size: 16, color: Colors.white),
                            )
                          : Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) => _onSelectionChanged(doc.id, value),
                              activeColor: const Color(0xFFFA5211),
                              checkColor: Colors.white,
                              side: BorderSide(color: subtextColor),
                            ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['name'] ?? 'Unnamed',
                                style: GoogleFonts.outfit(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${data['price'] ?? 0}',
                              style: GoogleFonts.outfit(color: const Color(0xFFFA5211)),
                            ),
                            if (isSpecial)
                               Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text('Today\'s Special', style: GoogleFonts.outfit(fontSize: 10, color: Colors.amber)),
                              )
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             if (!_viewingLive)
                                IconButton(
                                  icon: Icon(
                                    isSpecial ? Icons.star : Icons.star_border,
                                    color: isSpecial ? Colors.amber : iconColor,
                                  ),
                                  onPressed: () => _onSpecialChanged(doc.id, !isSpecial),
                                ),
                             Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: borderColor,
                                image: data['image'] != null && data['image'].toString().isNotEmpty
                                    ? DecorationImage(image: NetworkImage(data['image']), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: data['image'] == null || data['image'].toString().isEmpty
                                  ? Icon(Icons.fastfood, size: 20, color: iconColor)
                                  : null,
                            ),
                          ],
                        ),
                        onTap: () {
                           if (!_viewingLive) {
                              _onSelectionChanged(doc.id, !isSelected);
                           }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Only show the "Set as Live" button if changes have been made
          if (_hasChanges && !_viewingLive)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _confirmSetLive(context, user.uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFA5211),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Update & Set Live',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onSelectionChanged(String docId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedItemIds.add(docId);
      } else {
        _selectedItemIds.remove(docId);
      }
      _checkForChanges();
    });
  }

  void _onSpecialChanged(String docId, bool value) {
    setState(() {
      if (value) {
        _todaySpecialIds.add(docId);
      } else {
        _todaySpecialIds.remove(docId);
      }
      _checkForChanges();
    });
  }

  void _checkForChanges() {
    bool selectionChanged = !_areSetsEqual(_selectedItemIds, _initialSelectedItemIds);
    bool specialChanged = !_areSetsEqual(_todaySpecialIds, _initialTodaySpecialIds);
    _hasChanges = selectionChanged || specialChanged;
  }

  bool _areSetsEqual(Set<String> set1, Set<String> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2);
  }

  void _confirmSetLive(BuildContext context, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Confirm Updates', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        content: Text(
          'This will update your live menu. \n\n• ${_selectedItemIds.length} items will be visible to customers.\n• ${_todaySpecialIds.length} items marked as Today\'s Special.',
          style: GoogleFonts.outfit(color: subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: hintColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateLiveStatus(userId);
            },
            child: Text('Update Live', style: GoogleFonts.outfit(color: const Color(0xFFFA5211), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLiveStatus(String userId) async {
    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collectionRef = FirebaseFirestore.instance.collection('vendors').doc(userId).collection('menu');
      
      final snapshot = await collectionRef.get();
      
      for (var doc in snapshot.docs) {
        bool shouldBeLive = _selectedItemIds.contains(doc.id);
        bool isSpecial = _todaySpecialIds.contains(doc.id);
        
        batch.update(doc.reference, {
          'isAvailable': shouldBeLive,
          'isTodaySpecial': isSpecial,
        });
      }

      await batch.commit();

      // Update the vendor's 'hasLiveItems' status
      await FirebaseFirestore.instance.collection('vendors').doc(userId).update({
        'hasLiveItems': _selectedItemIds.isNotEmpty,
      });
      
      // Update initial state to match new saved state
      setState(() {
         _initialSelectedItemIds.clear();
         _initialSelectedItemIds.addAll(_selectedItemIds);
         _initialTodaySpecialIds.clear();
         _initialTodaySpecialIds.addAll(_todaySpecialIds);
         _hasChanges = false;
         _viewingLive = true; // Return to live view
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating menu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
