import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;
    final subtextColor2 = isDark ? Colors.white38 : Colors.black45;
    final borderColor = isDark ? Colors.white10 : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Order Details',
            style: GoogleFonts.outfit(
                color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFA5211)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
                child: Text('Order not found',
                    style: GoogleFonts.outfit(color: textColor)));
          }

          final order = snapshot.data!.data() as Map<String, dynamic>;
          final List items = order['items'] ?? [];
          final String status = order['status'] ?? 'Pending';
          final String vendorId = order['vendorId'] ?? '';
          final String vendorName = order['vendorName'] ?? 'Vendor';
          final double totalAmount = (order['totalAmount'] ?? 0).toDouble();
          final double subtotal = (order['subtotal'] ?? 0).toDouble();
          final double taxes = (order['taxes'] ?? 0).toDouble();
          final double deliveryFee = (order['deliveryFee'] ?? 0).toDouble();
          final Map<String, dynamic>? address = order['address'];
          final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
          final dateStr = createdAt != null
              ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt)
              : 'Recently';
          
          // Check if navigation should be shown
          final showNavigation = status.toLowerCase() != 'delivered' && 
                                  status.toLowerCase() != 'cancelled';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(status),
                          color: _getStatusColor(status), size: 30),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(status.toUpperCase(),
                                style: GoogleFonts.outfit(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            if (status.toLowerCase() == 'cancelled' && order['cancellationReason'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Reason: ${order['cancellationReason']}',
                                    style: GoogleFonts.outfit(
                                        color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            Text('Updated: $dateStr',
                                style: GoogleFonts.outfit(
                                    color: subtextColor2, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Navigate to Shop Button (only show if order is not delivered or cancelled)
                if (showNavigation && vendorId.isNotEmpty)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vendors')
                        .doc(vendorId)
                        .snapshots(),
                    builder: (context, vendorSnapshot) {
                      if (vendorSnapshot.hasData && vendorSnapshot.data!.exists) {
                        final vendorData = vendorSnapshot.data!.data() as Map<String, dynamic>;
                        final vendorLocation = vendorData['location'] as Map<String, dynamic>?;
                        
                        if (vendorLocation != null && 
                            vendorLocation['latitude'] != null && 
                            vendorLocation['longitude'] != null) {
                          final lat = vendorLocation['latitude'] as double;
                          final lng = vendorLocation['longitude'] as double;
                          
                          return Column(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFA5211), Color(0xFFFF7043)],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFA5211).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => _openInMaps(lat, lng, address),
                                  icon: const Icon(Icons.navigation, color: Colors.white),
                                  label: Text(
                                    'Navigate to Shop',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                // Shop Contact Information
                if (vendorId.isNotEmpty)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vendors')
                        .doc(vendorId)
                        .snapshots(),
                    builder: (context, vendorSnapshot) {
                      if (vendorSnapshot.hasData && vendorSnapshot.data!.exists) {
                        final vendorData = vendorSnapshot.data!.data() as Map<String, dynamic>;
                        final vendorPhone = vendorData['phone'] as String?;
                        
                        if (vendorPhone != null && vendorPhone.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Shop Contact',
                                  style: GoogleFonts.outfit(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 15),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFA5211).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.phone,
                                        color: Color(0xFFFA5211),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vendorName,
                                            style: GoogleFonts.outfit(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            vendorPhone,
                                            style: GoogleFonts.outfit(
                                              color: subtextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _callShop(vendorPhone),
                                      icon: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.call,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                // Order Summary Section
                Text('Order Summary',
                    style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendorName,
                          style: GoogleFonts.outfit(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Divider(height: 30, color: borderColor),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: NetworkImage(item['image'] ?? ''),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'],
                                          style: GoogleFonts.outfit(
                                              color: textColor,
                                              fontWeight: FontWeight.w600)),
                                      Text('Qty: ${item['quantity']}',
                                          style: GoogleFonts.outfit(
                                              color: subtextColor2,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text('₹${item['price'] * item['quantity']}',
                                    style: GoogleFonts.outfit(
                                        color: subtextColor,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Delivery Address
                Text('Delivery Details',
                    style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Color(0xFFFA5211)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(address?['label'] ?? 'Home',
                                style: GoogleFonts.outfit(
                                    color: textColor,
                                    fontWeight: FontWeight.bold)),
                            Text(address?['address'] ?? 'No address',
                                style: GoogleFonts.outfit(
                                    color: subtextColor, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Billing Detail
                Text('Billing Detail',
                    style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildBillRow('Item Total', '₹${subtotal.toInt()}', textColor, subtextColor),
                      _buildBillRow('Delivery Fee', '₹${deliveryFee.toInt()}', textColor, subtextColor),
                      _buildBillRow('Taxes & Charges', '₹${taxes.toInt()}', textColor, subtextColor),
                      Divider(height: 30, color: borderColor),
                      _buildBillRow('Total Amount', '₹${totalAmount.toInt()}',
                          textColor, subtextColor, isTotal: true),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Method',
                              style: GoogleFonts.outfit(
                                  color: subtextColor2, fontSize: 13)),
                          Text(order['paymentMethod'] ?? 'Cash',
                              style: GoogleFonts.outfit(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Cancel Order Button (only show for pending or received orders)
                if (_canCancelOrder(status))
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _showCancellationDialog(context),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: Text(
                        'Cancel Order',
                        style: GoogleFonts.outfit(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openInMaps(double shopLat, double shopLng, Map<String, dynamic>? address) async {
    try {
      // Try to get customer's current location for directions
      double? customerLat;
      double? customerLng;
      
      // First, try to use saved address location
      final addressLocation = address?['location'] as Map<String, dynamic>?;
      if (addressLocation != null && 
          addressLocation['latitude'] != null && 
          addressLocation['longitude'] != null) {
        customerLat = addressLocation['latitude'] as double?;
        customerLng = addressLocation['longitude'] as double?;
      }
      
      // Create Google Maps URL with directions
      Uri mapsUrl;
      if (customerLat != null && customerLng != null) {
        // Google Maps directions URL with origin and destination
        mapsUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=$customerLat,$customerLng&destination=$shopLat,$shopLng&travelmode=driving'
        );
      } else {
        // Fallback to just showing the shop location
        mapsUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$shopLat,$shopLng'
        );
      }
      
      // Try to launch the URL
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      // If web URL fails, try geo URI as fallback
      try {
        final geoUri = Uri.parse('geo:$shopLat,$shopLng');
        await launchUrl(geoUri);
      } catch (e) {
        // Silent fail - URL launcher will show error if needed
      }
    }
  }
  
  Future<void> _callShop(String phoneNumber) async {
    final telUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  bool _canCancelOrder(String status) {
    // Customers can only cancel pending or received orders
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'pending' || lowerStatus == 'received';
  }

  void _showCancellationDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;
    final hintColor = isDark ? Colors.white10 : Colors.black26;
    
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(
          'Cancel Order',
          style: GoogleFonts.outfit(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for cancellation:',
              style: GoogleFonts.outfit(
                color: subtextColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: reasonController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'e.g. Changed my mind, Ordered by mistake',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back',
              style: GoogleFonts.outfit(color: subtextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please provide a reason for cancellation',
                      style: GoogleFonts.outfit(),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              
              try {
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(widget.orderId)
                    .update({
                  'status': 'Cancelled',
                  'cancellationReason': reason,
                  'cancelledBy': 'customer',
                  'cancelledAt': FieldValue.serverTimestamp(),
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order cancelled successfully',
                        style: GoogleFonts.outfit(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to cancel order. Please try again.',
                        style: GoogleFonts.outfit(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Confirm Cancellation',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, Color textColor, Color subtextColor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  color: isTotal ? textColor : subtextColor,
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: GoogleFonts.outfit(
                  color: isTotal ? const Color(0xFFFA5211) : textColor,
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'received':
        return Colors.orangeAccent;
      case 'cooking':
        return Colors.blue;
      case 'ready':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.white54;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.receipt_long;
      case 'received':
        return Icons.check_circle_outline;
      case 'cooking':
        return Icons.restaurant;
      case 'ready':
        return Icons.done_all;
      case 'delivered':
        return Icons.home_work;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
