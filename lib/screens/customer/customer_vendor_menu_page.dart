import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/cart_service.dart';
import 'food_item_details_page.dart';
import 'cart_page.dart';

class CustomerVendorMenuPage extends StatelessWidget {
  final String vendorId;
  final String? vendorName;
  final String? vendorImage;

  const CustomerVendorMenuPage({
    super.key,
    required this.vendorId,
    this.vendorName,
    this.vendorImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;
    final iconColor = isDark ? Colors.white24 : Colors.grey;
    final borderColor = isDark ? Colors.white10 : Colors.grey[300]!;
    final imagePlaceholderBg = isDark ? Colors.white10 : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('vendors').doc(vendorId).snapshots(),
        builder: (context, vendorSnapshot) {
          // Use provided data or fallback to fetched data
          String displayVendorName = vendorName ?? 'Loading...';
          String displayVendorImage = vendorImage ?? '';
          String displayVendorAddress = 'Loading...';
          double? vendorLat;
          double? vendorLng;
          
          if (vendorSnapshot.hasData && vendorSnapshot.data!.exists) {
            final data = vendorSnapshot.data!.data() as Map<String, dynamic>;
            displayVendorName = data['businessName'] ?? displayVendorName;
            displayVendorImage = data['businessImage'] ?? displayVendorImage;
            
            // Get location data
            final location = data['location'] as Map<String, dynamic>?;
            if (location != null && location['latitude'] != null && location['longitude'] != null) {
              vendorLat = location['latitude'] as double;
              vendorLng = location['longitude'] as double;
              displayVendorAddress = 'Lat: ${vendorLat!.toStringAsFixed(4)}, Lng: ${vendorLng!.toStringAsFixed(4)}';
            } else {
              displayVendorAddress = 'Location not set';
            }
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: backgroundColor,
                actions: [
                  if (vendorLat != null && vendorLng != null)
                    IconButton(
                      icon: const Icon(Icons.location_on),
                      onPressed: () => _openInMaps(vendorLat!, vendorLng!),
                      tooltip: 'View Location',
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(displayVendorName, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
                      if (displayVendorAddress != 'Location not set')
                        Text(
                          displayVendorAddress, 
                          style: GoogleFonts.outfit(color: subtextColor, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                       displayVendorImage.isNotEmpty
                          ? Image.network(displayVendorImage, fit: BoxFit.cover)
                          : Container(color: surfaceColor, child: Icon(Icons.store, color: iconColor, size: 50)),
                       Container(
                         decoration: BoxDecoration(
                           gradient: LinearGradient(
                             begin: Alignment.topCenter,
                             end: Alignment.bottomCenter,
                             colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                           ),
                         ),
                       ),
                    ],
                  ),
                ),
              ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Text("Today's Menu", style: GoogleFonts.outfit(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vendors')
                .doc(vendorId)
                .collection('menu')
                .where('isAvailable', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Color(0xFFFA5211))));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Text('No live items available right now.', style: GoogleFonts.outfit(color: subtextColor)),
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = docs[index].data() as Map<String, dynamic>;
                    bool isSpecial = item['isTodaySpecial'] == true;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodItemDetailsPage(
                              item: item,
                              itemId: docs[index].id,
                              vendorId: vendorId,
                              vendorName: displayVendorName,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          if (isSpecial)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFA5211),
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text("Today's Special", style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: imagePlaceholderBg,
                                    image: item['image'] != null && item['image'].toString().isNotEmpty
                                        ? DecorationImage(image: NetworkImage(item['image']), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: item['image'] == null || item['image'].toString().isEmpty
                                      ? Icon(Icons.fastfood, color: iconColor)
                                      : null,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Veg/Non-Veg Indicator
                                          if (item['itemType'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: item['itemType'] == 'veg' 
                                                        ? Colors.green 
                                                        : Colors.red,
                                                    width: 2,
                                                  ),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: item['itemType'] == 'veg' 
                                                          ? Colors.green 
                                                          : Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              item['name'] ?? 'Unnamed',
                                              style: GoogleFonts.outfit(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['description'] ?? 'No description',
                                        style: GoogleFonts.outfit(color: subtextColor, fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${item['price'] ?? 0}',
                                            style: GoogleFonts.outfit(color: const Color(0xFFFA5211), fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          if (item['preparationTime'] != null) ...[
                                            const SizedBox(width: 12),
                                            Icon(Icons.timer_outlined, color: subtextColor, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${item['preparationTime']} min',
                                              style: GoogleFonts.outfit(color: subtextColor, fontSize: 12),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_shopping_cart, color: Color(0xFFFA5211)),
                                  onPressed: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please login to add to cart'), backgroundColor: Colors.red),
                                      );
                                      return;
                                    }
                                    
                                    final cartItem = {
                                      'id': docs[index].id,
                                      'name': item['name'],
                                      'price': item['price'],
                                      'image': item['image'],
                                      'vendorId': vendorId,
                                      'vendorName': displayVendorName,
                                      'itemType': item['itemType'],
                                      'preparationTime': item['preparationTime'],
                                    };

                                    try {
                                      await CartService().addToCart(user.uid, cartItem);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${item['name']} added to cart'),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 2),
                                            action: SnackBarAction(
                                              label: 'View Cart',
                                              textColor: Colors.white,
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => const CartPage()),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to add to cart: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    );
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),
        ],
      );
    },
  ),
);
  }

  Future<void> _openInMaps(double latitude, double longitude) async {
    final geoUri = Uri.parse('geo:$latitude,$longitude');
    
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      // Fallback to Google Maps web URL
      final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    }
  }
}
