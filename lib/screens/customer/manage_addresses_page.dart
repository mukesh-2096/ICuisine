import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../vendor/map_location_picker.dart';

class ManageAddressesPage extends StatefulWidget {
  const ManageAddressesPage({super.key});

  @override
  State<ManageAddressesPage> createState() => _ManageAddressesPageState();
}

class _ManageAddressesPageState extends State<ManageAddressesPage> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  Map<String, double>? _selectedLocation;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _addAddress() async {
    if (_labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a label for this address')),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final addressData = {
        'label': _labelController.text.trim(),
        'location': {
          'latitude': _selectedLocation!['latitude'],
          'longitude': _selectedLocation!['longitude'],
        },
        'isDefault': _isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_isDefault) {
        // Unset previous defaults
        final query = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .collection('addresses')
            .where('isDefault', isEqualTo: true)
            .get();
        
        for (var doc in query.docs) {
          await doc.reference.update({'isDefault': false});
        }
      }

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .collection('addresses')
          .add(addressData);

      _labelController.clear();
      _selectedLocation = null;
      setState(() => _isDefault = false);
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding address: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefault(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .collection('addresses')
          .where('isDefault', isEqualTo: true)
          .get();
      
      for (var doc in query.docs) {
        await doc.reference.update({'isDefault': false});
      }

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .collection('addresses')
          .doc(addressId)
          .update({'isDefault': true});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error setting default: $e')));
      }
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .collection('addresses')
          .doc(addressId)
          .delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting address: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final iconBackground = isDark ? Colors.white10 : Colors.black12;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final borderColor = isDark ? Colors.white10 : Colors.black12;
    final iconHintColor = isDark ? Colors.white38 : Colors.black38;
    final surfaceIconColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('My Addresses', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAddressDialog,
        backgroundColor: const Color(0xFFFA5211),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customers')
            .doc(user?.uid)
            .collection('addresses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 80, color: iconBackground),
                  const SizedBox(height: 20),
                  Text('No addresses saved yet', style: GoogleFonts.outfit(color: hintColor, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              bool isDefault = data['isDefault'] ?? false;
              
              // Get location data
              final location = data['location'] as Map<String, dynamic>?;
              String locationText;
              if (location != null && location['latitude'] != null && location['longitude'] != null) {
                final lat = location['latitude'] as double;
                final lng = location['longitude'] as double;
                locationText = 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
              } else {
                locationText = 'Location not set';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDefault ? const Color(0xFFFA5211).withOpacity(0.5) : borderColor),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDefault ? const Color(0xFFFA5211).withOpacity(0.1) : surfaceIconColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on, color: isDefault ? const Color(0xFFFA5211) : iconHintColor),
                  ),
                  title: Row(
                    children: [
                      Text(data['label'] ?? 'Address', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFA5211), borderRadius: BorderRadius.circular(5)),
                          child: Text('Default', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(locationText, style: GoogleFonts.outfit(color: subtextColor, fontSize: 14)),
                  ),
                  trailing: PopupMenuButton<String>(
                    color: surfaceColor,
                    icon: Icon(Icons.more_vert, color: iconHintColor),
                    onSelected: (value) {
                      if (value == 'default') _setDefault(doc.id);
                      if (value == 'delete') _deleteAddress(doc.id);
                    },
                    itemBuilder: (context) => [
                      if (!isDefault)
                        PopupMenuItem(value: 'default', child: Text('Set as Default', style: TextStyle(color: textColor))),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddAddressDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final borderColor = isDark ? Colors.white10 : Colors.black12;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add New Address', style: GoogleFonts.outfit(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Label TextField
                TextFormField(
                  controller: _labelController,
                  style: GoogleFonts.outfit(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Label (e.g. Home, Office) *',
                    labelStyle: GoogleFonts.outfit(color: hintColor),
                    prefixIcon: const Icon(Icons.label_outline, color: Color(0xFFFA5211)),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFFA5211))),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Location Picker Button
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<Map<String, double>>(
                      context,
                      MaterialPageRoute(builder: (context) => const MapLocationPicker()),
                    );
                    if (result != null) {
                      setModalState(() {
                        _selectedLocation = result;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _selectedLocation != null ? const Color(0xFFFA5211) : borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: _selectedLocation != null ? const Color(0xFFFA5211) : iconColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location *',
                                style: GoogleFonts.outfit(color: hintColor, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedLocation != null
                                    ? 'Lat: ${_selectedLocation!['latitude']!.toStringAsFixed(4)}, Lng: ${_selectedLocation!['longitude']!.toStringAsFixed(4)}'
                                    : 'Tap to select location on map',
                                style: GoogleFonts.outfit(
                                  color: _selectedLocation != null ? textColor : hintColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Set as Default Checkbox
                CheckboxListTile(
                  title: Text('Set as Default Address *', style: GoogleFonts.outfit(color: iconColor, fontSize: 14)),
                  value: _isDefault,
                  activeColor: const Color(0xFFFA5211),
                  checkColor: Colors.white,
                  onChanged: (value) {
                    setModalState(() => _isDefault = value ?? false);
                    setState(() => _isDefault = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 30),
                
                // Add Address Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFA5211),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Add Address', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
