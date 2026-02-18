import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'order_details_page.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white38 : Colors.black54;
    final hintColor = isDark ? Colors.white24 : Colors.black26;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final iconBackground = isDark ? Colors.white10 : Colors.black12;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final borderColor = isDark ? Colors.white10 : Colors.black12;
    
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: Text('Please login to view orders', style: GoogleFonts.outfit(color: textColor))),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('customerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          }

          final orders = snapshot.data?.docs ?? [];
          
          final sortedOrders = List<QueryDocumentSnapshot>.from(orders);
          sortedOrders.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          if (sortedOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: iconBackground),
                  const SizedBox(height: 20),
                  Text('No orders yet', style: GoogleFonts.outfit(color: subtextColor, fontSize: 18)),
                  const SizedBox(height: 10),
                  Text('Order something delicious!', style: GoogleFonts.outfit(color: hintColor, fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: sortedOrders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final orderDoc = sortedOrders[index];
              final order = orderDoc.data() as Map<String, dynamic>;
              final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
              final dateStr = createdAt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt) : 'Recently';
              
              final List items = order['items'] ?? [];
              final String itemsSummary = items.map((i) => i['name']).join(', ');
              final String vendorName = order['vendorName'] ?? 'Unknown Vendor';
              final String status = order['status'] ?? 'Pending';
              final double total = (order['totalAmount'] ?? 0).toDouble();

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsPage(orderId: orderDoc.id),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                            vendorName,
                            style: GoogleFonts.outfit(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                          Text('₹${total.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                  color: const Color(0xFFFA5211),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(itemsSummary,
                          style: GoogleFonts.outfit(
                              color: subtextColor, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Divider(height: 24, color: borderColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ORDER ID',
                                  style: GoogleFonts.outfit(
                                      color: hintColor,
                                      fontSize: 9,
                                      letterSpacing: 1)),
                              Text(
                                  '#${orderDoc.id.substring(0, 8).toUpperCase()}',
                                  style: GoogleFonts.outfit(
                                      color: subtextColor, fontSize: 11)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: _getStatusColor(status),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(dateStr,
                          style: GoogleFonts.outfit(
                              color: hintColor, fontSize: 11)),
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
}
