import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_addresses_page.dart';
import 'my_orders_page.dart';
import '../../services/cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();

  bool _isPlacingOrder = false;

  Future<void> _updateQuantity(String userId, String itemId, int currentQuantity, int delta) async {
    await _cartService.updateQuantity(userId, itemId, currentQuantity + delta);
  }

  Future<void> _placeOrder({
    required User user,
    required List<Map<String, dynamic>> cartItems,
    required double subtotal,
    required double deliveryFee,
    required double taxes,
    required double total,
  }) async {
    if (cartItems.isEmpty) return;

    // 1. Check Address First
    final addressSnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (addressSnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please add a delivery address first!"),
              backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final addressData = addressSnapshot.docs.first.data();
    final Map<String, dynamic> orderAddress = {
      'address': addressData['address'],
      'label': addressData['label'],
      'phone': addressData['phone'],
    };

    // 2. Show Payment Selection
    if (mounted) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
      final subtextColor = isDark ? Colors.white54 : Colors.black54;
      final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
      final borderColor = isDark ? Colors.white10 : Colors.black12;
      
      String? selectedMethod;
      showModalBottomSheet(
        context: context,
        backgroundColor: surfaceColor,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Payment Method',
                    style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                _buildPaymentOption(
                  icon: Icons.money,
                  title: 'Cash on Delivery',
                  subtitle: 'Pay when your food arrives',
                  isSelected: selectedMethod == 'Cash',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  borderColor: borderColor,
                  onTap: () {
                    setSheetState(() => selectedMethod = 'Cash');
                  },
                ),
                const SizedBox(height: 15),
                _buildPaymentOption(
                  icon: Icons.qr_code_scanner,
                  title: 'UPI / QR Code',
                  subtitle: 'Scan and pay instantly',
                  isSelected: selectedMethod == 'UPI',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  borderColor: borderColor,
                  onTap: () {
                    setSheetState(() => selectedMethod = 'UPI');
                  },
                ),
                const SizedBox(height: 30),
                if (selectedMethod != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (selectedMethod == 'Cash') {
                          _processFinalOrder(
                              user: user,
                              cartItems: cartItems,
                              orderAddress: orderAddress,
                              paymentMethod: 'Cash');
                        } else {
                          _showUPIDialog(
                              user: user,
                              cartItems: cartItems,
                              orderAddress: orderAddress,
                              total: total);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFA5211),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('PLACE ORDER',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1)),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPaymentOption(
      {required IconData icon,
      required String title,
      required String subtitle,
      required bool isSelected,
      required Color textColor,
      required Color subtextColor,
      required Color borderColor,
      required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: isSelected ? const Color(0xFFFA5211) : borderColor,
              width: isSelected ? 2 : 1)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFA5211)
                : const Color(0xFFFA5211).withOpacity(0.1),
            shape: BoxShape.circle),
        child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFFFA5211)),
      ),
      title: Text(title,
          style: GoogleFonts.outfit(
              color: textColor, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: GoogleFonts.outfit(color: subtextColor, fontSize: 12)),
      trailing: isSelected 
          ? const Icon(Icons.check_circle, color: Color(0xFFFA5211))
          : Icon(Icons.chevron_right, color: subtextColor.withOpacity(0.5)),
    );
  }

  void _showUPIDialog(
      {required User user,
      required List<Map<String, dynamic>> cartItems,
      required Map<String, dynamic> orderAddress,
      required double total}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scan & Pay',
                style: GoogleFonts.outfit(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=iCuisine-Payment-Total-${total.toStringAsFixed(0)}',
                height: 200,
                width: 200,
              ),
            ),
            const SizedBox(height: 20),
            Text('Amount to pay: ₹${total.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                    color: const Color(0xFFFA5211),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 10),
            Text('After payment, click the button below to complete order.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: subtextColor, fontSize: 12)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processFinalOrder(
                      user: user,
                      cartItems: cartItems,
                      orderAddress: orderAddress,
                      paymentMethod: 'UPI');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFA5211),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: Text('Payment Done & Place Order',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processFinalOrder({
    required User user,
    required List<Map<String, dynamic>> cartItems,
    required Map<String, dynamic> orderAddress,
    required String paymentMethod,
  }) async {
    setState(() => _isPlacingOrder = true);

    try {
      // 2. Group items by vendorId
      final Map<String, List<Map<String, dynamic>>> vendorGroups = {};
      final Map<String, String> vendorNames = {};

      for (var item in cartItems) {
        final vId = item['vendorId'] as String;
        if (!vendorGroups.containsKey(vId)) {
          vendorGroups[vId] = [];
          vendorNames[vId] = item['vendorName'] ?? 'Unknown Vendor';
        }
        vendorGroups[vId]!.add(item);
      }

      final batch = FirebaseFirestore.instance.batch();

      // 3. Create an order for each vendor
      for (var vId in vendorGroups.keys) {
        final groupItems = vendorGroups[vId]!;
        double groupSubtotal = 0;
        for (var item in groupItems) {
          groupSubtotal += (item['price'] as double) * (item['quantity'] as int);
        }

        final groupTaxes = groupSubtotal * 0.05;
        final groupTotal = groupSubtotal + 0 + groupTaxes;

        final orderRef = FirebaseFirestore.instance.collection('orders').doc();
        batch.set(orderRef, {
          'orderId': orderRef.id,
          'customerId': user.uid,
          'customerName': user.displayName ?? 'Customer',
          'vendorId': vId,
          'vendorName': vendorNames[vId],
          'items': groupItems
              .map((item) => {
                    'itemId': item['id'],
                    'name': item['name'],
                    'price': item['price'],
                    'image': item['image'],
                    'quantity': item['quantity'],
                  })
              .toList(),
          'subtotal': groupSubtotal,
          'deliveryFee': 0.0,
          'taxes': groupTaxes,
          'totalAmount': groupTotal,
          'address': orderAddress,
          'status': 'Pending',
          'paymentMethod': paymentMethod,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'delivery',
        });
      }

      await batch.commit();

      // 4. Clear Cart
      await _cartService.clearCart(user.uid);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 20),
                Text('Order Placed!',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Your order has been sent to the vendor.',
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyOrdersPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFA5211),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Done',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to place order: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
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
    final quantityBg = isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5);
    
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text('Please login to view cart', style: GoogleFonts.outfit(color: textColor)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _cartService.getCartStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211))),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: Colors.red))),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        
        // Calculate totals
        double subtotal = 0;
        final cartItems = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Ensure price and quantity are treated as numbers
          final price = (data['price'] ?? 0).toDouble();
          final quantity = (data['quantity'] ?? 0).toInt();
          subtotal += price * quantity;
          return {
            ...data,
            'id': doc.id, // Stores the cart item ID
            'price': price,
            'quantity': quantity,
          };
        }).toList();

        final deliveryFee = 0.0;
        final taxes = subtotal * 0.05;
        final total = subtotal + deliveryFee + taxes;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text('My Cart', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
            backgroundColor: backgroundColor,
            elevation: 0,
            centerTitle: true,
          ),
          body: cartItems.isEmpty 
              ? _buildEmptyCart(backgroundColor, surfaceColor, iconBackground, textColor, hintColor) 
              : _buildCartContent(user, cartItems, subtotal, deliveryFee, taxes, total, surfaceColor, borderColor, textColor, subtextColor, hintColor, iconColor, quantityBg),
          bottomNavigationBar: cartItems.isEmpty
              ? null
              : _buildBottomAction(
                  user: user,
                  cartItems: cartItems,
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
                  taxes: taxes,
                  total: total,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
        );
      },
    );
  }

  Widget _buildEmptyCart(Color backgroundColor, Color surfaceColor, Color iconBackground, Color textColor, Color hintColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined, size: 80, color: iconBackground),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.outfit(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Looks like you haven\'t added anything\nto your cart yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: hintColor, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Usually navigate back or to home
              Navigator.pop(context); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA5211),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text('Browse Dishes', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(User user, List<Map<String, dynamic>> cartItems, double subtotal, double deliveryFee, double taxes, double total, Color surfaceColor, Color borderColor, Color textColor, Color subtextColor, Color hintColor, Color iconColor, Color quantityBg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cartItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: item['image'] != null
                        ? Image.network(
                            item['image'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                Container(width: 80, height: 80, color: Colors.grey, child: const Icon(Icons.error)),
                          )
                        : Container(width: 80, height: 80, color: Colors.white10, child: const Icon(Icons.fastfood)),
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
                                    width: 16,
                                    height: 16,
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
                                        width: 7,
                                        height: 7,
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
                                  item['name'] ?? 'Unknown Item',
                                  style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            item['vendorName'] ?? 'Unknown Vendor',
                            style: GoogleFonts.outfit(color: hintColor, fontSize: 12),
                          ),
                          if (item['preparationTime'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.timer_outlined, color: hintColor, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item['preparationTime']} min',
                                    style: GoogleFonts.outfit(color: hintColor, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            '₹${item['price']}',
                            style: GoogleFonts.outfit(color: const Color(0xFFFA5211), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    // Quantity Controls
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: quantityBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _updateQuantity(user.uid, item['id'], item['quantity'], -1),
                            child: Icon(Icons.remove, color: iconColor, size: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item['quantity']}',
                              style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _updateQuantity(user.uid, item['id'], item['quantity'], 1),
                            child: const Icon(Icons.add, color: Color(0xFFFA5211), size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 30),
          
          // Address Section
          _buildSectionHeader('Delivery Address', textColor),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                    .collection('customers')
                    .doc(user.uid)
                    .collection('addresses')
                    .where('isDefault', isEqualTo: true)
                    .snapshots(),
            builder: (context, snapshot) {
              String addressText = 'No default address set';
              String label = 'Location';
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                addressText = data['address'] ?? '';
                label = data['label'] ?? 'Home';
              }
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFA5211).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Color(0xFFFA5211), size: 18),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(addressText, style: GoogleFonts.outfit(color: subtextColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageAddressesPage()));
                      },
                      child: Text('Change', style: GoogleFonts.outfit(color: const Color(0xFFFA5211), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // Bill Summary
          _buildSectionHeader('Bill Summary', textColor),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _buildBillRow('Item Total', '₹${subtotal.toStringAsFixed(0)}', textColor, subtextColor),
                const SizedBox(height: 12),
                _buildBillRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(0)}', textColor, subtextColor),
                const SizedBox(height: 12),
                _buildBillRow('Taxes & Charges (5%)', '₹${taxes.toStringAsFixed(0)}', textColor, subtextColor),
                Divider(height: 30, color: borderColor),
                _buildBillRow('Grand Total', '₹${total.toStringAsFixed(0)}', textColor, subtextColor, isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBillRow(String label, String value, Color textColor, Color subtextColor, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: isTotal ? textColor : subtextColor,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isTotal ? const Color(0xFFFA5211) : textColor,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction({
    required User user,
    required List<Map<String, dynamic>> cartItems,
    required double subtotal,
    required double deliveryFee,
    required double taxes,
    required double total,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isPlacingOrder
              ? null
              : () => _placeOrder(
                    user: user,
                    cartItems: cartItems,
                    subtotal: subtotal,
                    deliveryFee: deliveryFee,
                    taxes: taxes,
                    total: total,
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFA5211),
            minimumSize: const Size(double.infinity, 55),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: _isPlacingOrder
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${total.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text('TOTAL AMOUNT',
                            style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 0.5)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Place Order',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
