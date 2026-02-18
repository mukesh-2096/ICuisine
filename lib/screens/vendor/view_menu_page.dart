import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_menu_item_page.dart';

class ViewMenuPage extends StatelessWidget {
  final bool showOnlyTodaySpecial;
  const ViewMenuPage({super.key, this.showOnlyTodaySpecial = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white38 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final borderColor = isDark ? Colors.white10 : Colors.black12;
    final iconDisabledColor = isDark ? Colors.white10 : Colors.black12;
    final iconColor = isDark ? Colors.white24 : Colors.black26;
    
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: Text('Please login to view menu', style: GoogleFonts.outfit(color: subtextColor))),
      );
    }

    Query<Map<String, dynamic>> menuQuery = FirebaseFirestore.instance
        .collection('vendors')
        .doc(user.uid)
        .collection('menu');

    if (showOnlyTodaySpecial) {
      menuQuery = menuQuery.where('isTodaySpecial', isEqualTo: true);
    }

    menuQuery = menuQuery.orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          showOnlyTodaySpecial ? "Today's Specials" : 'My Menu',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: menuQuery.snapshots(),
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
                  Icon(Icons.restaurant_menu, size: 80, color: iconDisabledColor),
                  const SizedBox(height: 20),
                  Text(
                    'No menu items yet',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tell your customers what you offer!',
                    style: GoogleFonts.outfit(color: subtextColor),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddMenuItemPage()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFA5211),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      image: data['image'] != null && data['image'].toString().isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(data['image']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: data['image'] == null || data['image'].toString().isEmpty
                        ? Icon(Icons.fastfood, color: iconColor)
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['name'] ?? 'Unnamed Item',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                        ),
                      ),
                      if (data['isTodaySpecial'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFA5211).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFA5211).withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Today\'s Special',
                            style: TextStyle(color: Color(0xFFFA5211), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        data['description'] ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(color: subtextColor, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${data['price']}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFA5211),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => _deleteItem(context, user.uid, doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMenuItemPage()),
          );
        },
        backgroundColor: const Color(0xFFFA5211),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _deleteItem(BuildContext context, String vendorId, String itemId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black45;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Delete Item', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove this item from your menu?', style: GoogleFonts.outfit(color: subtextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: iconColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('vendors')
                  .doc(vendorId)
                  .collection('menu')
                  .doc(itemId)
                  .delete();
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
