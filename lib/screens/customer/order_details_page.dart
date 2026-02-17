import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Order Details',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFA5211)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
                child: Text('Order not found',
                    style: GoogleFonts.outfit(color: Colors.white)));
          }

          final order = snapshot.data!.data() as Map<String, dynamic>;
          final List items = order['items'] ?? [];
          final String status = order['status'] ?? 'Pending';
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
                                    color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Order Summary Section
                Text('Order Summary',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendorName,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const Divider(height: 30, color: Colors.white10),
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
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600)),
                                      Text('Qty: ${item['quantity']}',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white38,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text('₹${item['price'] * item['quantity']}',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70,
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
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            Text(address?['address'] ?? 'No address',
                                style: GoogleFonts.outfit(
                                    color: Colors.white54, fontSize: 13)),
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
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _buildBillRow('Item Total', '₹${subtotal.toInt()}'),
                      _buildBillRow('Delivery Fee', '₹${deliveryFee.toInt()}'),
                      _buildBillRow('Taxes & Charges', '₹${taxes.toInt()}'),
                      const Divider(height: 30, color: Colors.white10),
                      _buildBillRow('Total Amount', '₹${totalAmount.toInt()}',
                          isTotal: true),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Method',
                              style: GoogleFonts.outfit(
                                  color: Colors.white38, fontSize: 13)),
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
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  color: isTotal ? Colors.white : Colors.white54,
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: GoogleFonts.outfit(
                  color: isTotal ? const Color(0xFFFA5211) : Colors.white,
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
