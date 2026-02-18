import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'customer_vendor_menu_page.dart';

class NearbyVendorsMap extends StatefulWidget {
  const NearbyVendorsMap({super.key});

  @override
  State<NearbyVendorsMap> createState() => _NearbyVendorsMapState();
}

class _NearbyVendorsMapState extends State<NearbyVendorsMap> {
  final MapController _mapController = MapController();
  final LatLng _initialPosition = const LatLng(20.5937, 78.9629); // India center

  Widget _darkModeTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.8, 0, 0, 0, 255,
        0, -0.8, 0, 0, 255,
        0, 0, -0.8, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Nearby Vendors', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Center(
          child: Text('Please login to view nearby vendors', style: GoogleFonts.outfit(color: textColor)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Vendors', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .collection('addresses')
            .where('isDefault', isEqualTo: true)
            .limit(1)
            .snapshots(),
        builder: (context, addressSnapshot) {
          if (addressSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)));
          }

          if (!addressSnapshot.hasData || addressSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Please set a default address to see nearby vendors',
                  style: GoogleFonts.outfit(color: textColor, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final addressData = addressSnapshot.data!.docs.first.data() as Map<String, dynamic>;
          final customerLocation = addressData['location'] as Map<String, dynamic>?;
          
          if (customerLocation == null || customerLocation['latitude'] == null || customerLocation['longitude'] == null) {
            return Center(
              child: Text('Invalid address location', style: GoogleFonts.outfit(color: Colors.red)),
            );
          }

          final customerLat = customerLocation['latitude'] as double;
          final customerLng = customerLocation['longitude'] as double;
          final customerPosition = LatLng(customerLat, customerLng);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vendors').snapshots(),
            builder: (context, vendorSnapshot) {
              if (vendorSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)));
              }

              if (vendorSnapshot.hasError) {
                return Center(
                  child: Text('Error loading vendors', style: GoogleFonts.outfit(color: Colors.red)),
                );
              }

              List<Marker> markers = [];
              
              // Add customer location marker
              markers.add(
                Marker(
                  point: customerPosition,
                  width: 40,
                  height: 40,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_pin, color: Colors.white, size: 24),
                  ),
                ),
              );
              
              if (vendorSnapshot.hasData) {
                for (var doc in vendorSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final location = data['location'] as Map<String, dynamic>?;
                  
                  if (location != null && location['latitude'] != null && location['longitude'] != null) {
                    final lat = location['latitude'] as double;
                    final lng = location['longitude'] as double;
                    
                    // Calculate distance
                    final distance = Geolocator.distanceBetween(
                      customerLat,
                      customerLng,
                      lat,
                      lng,
                    );
                    
                    // Only show vendors within 50km
                    if (distance <= 50000) {
                      final businessName = data['businessName'] ?? 'Unknown';
                      final businessImage = data['businessImage'] ?? '';

                      markers.add(
                        Marker(
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              _showVendorDetails(context, doc.id, businessName, businessImage, data, distance);
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFA5211),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.store, color: Colors.white, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: customerPosition,
                  initialZoom: 12,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.icuisine',
                    tileBuilder: isDark ? _darkModeTileBuilder : null,
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showVendorDetails(BuildContext context, String vendorId, String businessName, String businessImage, Map<String, dynamic> data, double distance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    
    // Format distance
    String distanceText;
    if (distance < 1000) {
      distanceText = '${distance.toStringAsFixed(0)}m away';
    } else {
      distanceText = '${(distance / 1000).toStringAsFixed(1)}km away';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: businessImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(businessImage, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.store, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Color(0xFFFA5211)),
                          const SizedBox(width: 4),
                          Text(
                            distanceText,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFFFA5211),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerVendorMenuPage(
                        vendorId: vendorId,
                        vendorName: businessName,
                        vendorImage: businessImage,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFA5211),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('View Menu', style: GoogleFonts.outfit(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
