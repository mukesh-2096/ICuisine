import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VendorOrderDetailsPage extends StatelessWidget {
  final String orderId;

  const VendorOrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white38 : Colors.black54;
    final subtextColor2 = isDark ? Colors.white54 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final borderColor = isDark ? Colors.white10 : Colors.black12;
    final iconDisabledColor = isDark ? Colors.white10 : Colors.black12;
    final iconColor = isDark ? Colors.white38 : Colors.black45;
    
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
                    style: GoogleFonts.outfit(color: textColor)));
          }

          final order = snapshot.data!.data() as Map<String, dynamic>;
          final List items = order['items'] ?? [];
          final String status = order['status'] ?? 'Pending';
          final String customerId = order['customerId'] ?? 'Unknown';
          final double totalAmount = (order['totalAmount'] ?? 0).toDouble();
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
                              Text('Reason: ${order['cancellationReason']}',
                                  style: GoogleFonts.outfit(
                                      color: Colors.redAccent, fontSize: 13)),
                            Text('Updated: $dateStr',
                                style: GoogleFonts.outfit(
                                    color: subtextColor, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Customer Info
                Text('Customer Info',
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
                      CircleAvatar(
                        backgroundColor: iconDisabledColor,
                        child: Icon(Icons.person, color: iconColor),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer ID',
                                style: GoogleFonts.outfit(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text('#${customerId.substring(0, customerId.length < 8 ? customerId.length : 8).toUpperCase()}',
                                style: GoogleFonts.outfit(
                                    color: subtextColor, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Delivery Address
                Text('Delivery Address',
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
                            Text(address?['label'] ?? 'Delivery Address',
                                style: GoogleFonts.outfit(
                                    color: textColor,
                                    fontWeight: FontWeight.bold)),
                            Text(address?['address'] ?? 'No address provided',
                                style: GoogleFonts.outfit(
                                    color: subtextColor2, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Order Items
                Text('Items Ordered',
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
                    children: items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: NetworkImage(item['image'] ?? ''),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'],
                                        style: GoogleFonts.outfit(
                                            color: textColor,
                                            fontWeight: FontWeight.w600)),
                                    Text('Quantity: ${item['quantity']}',
                                        style: GoogleFonts.outfit(
                                            color: subtextColor,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text('₹${(item['price'] * item['quantity']).toInt()}',
                                  style: GoogleFonts.outfit(
                                      color: textColor,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )).toList(),
                  ),
                ),

                const SizedBox(height: 30),

                // Order Totals
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFA5211).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFA5211).withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Earnings from this order',
                              style: GoogleFonts.outfit(
                                  color: Colors.white38, fontSize: 12)),
                          Text('₹${totalAmount.toInt()}',
                              style: GoogleFonts.outfit(
                                  color: const Color(0xFFFA5211),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          order['paymentMethod']?.toString().toUpperCase() ?? 'COD',
                          style: GoogleFonts.outfit(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'received': return Colors.orangeAccent;
      case 'cooking': return Colors.blue;
      case 'ready': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.white54;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.receipt_long;
      case 'received': return Icons.check_circle_outline;
      case 'cooking': return Icons.restaurant;
      case 'ready': return Icons.done_all;
      case 'delivered': return Icons.home_work;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }
}
