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
      String? selectedMethod;
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
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
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                _buildPaymentOption(
                  icon: Icons.money,
                  title: 'Cash on Delivery',
                  subtitle: 'Pay when your food arrives',
                  isSelected: selectedMethod == 'Cash',
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
      required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: isSelected ? const Color(0xFFFA5211) : Colors.white10,
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
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
      trailing: isSelected 
          ? const Icon(Icons.check_circle, color: Color(0xFFFA5211))
          : const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }

  void _showUPIDialog(
      {required User user,
      required List<Map<String, dynamic>> cartItems,
      required Map<String, dynamic> orderAddress,
      required double total}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scan & Pay',
                style: GoogleFonts.outfit(
                    color: Colors.white,
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
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Done',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Text('Please login to view cart', style: GoogleFonts.outfit(color: Colors.white)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _cartService.getCartStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFFA5211))),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
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
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: Text('My Cart', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            centerTitle: true,
          ),
          body: cartItems.isEmpty 
              ? _buildEmptyCart() 
              : _buildCartContent(user, cartItems, subtotal, deliveryFee, taxes, total),
          bottomNavigationBar: cartItems.isEmpty
              ? null
              : _buildBottomAction(
                  user: user,
                  cartItems: cartItems,
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
                  taxes: taxes,
                  total: total,
                ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.white10),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Looks like you haven\'t added anything\nto your cart yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
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

  Widget _buildCartContent(User user, List<Map<String, dynamic>> cartItems, double subtotal, double deliveryFee, double taxes, double total) {
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
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
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
                          Text(
                            item['name'] ?? 'Unknown Item',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            item['vendorName'] ?? 'Unknown Vendor',
                            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
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
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _updateQuantity(user.uid, item['id'], item['quantity'], -1),
                            child: const Icon(Icons.remove, color: Colors.white70, size: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item['quantity']}',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
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
          _buildSectionHeader('Delivery Address'),
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
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
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
                          Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(addressText, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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
          _buildSectionHeader('Bill Summary'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildBillRow('Item Total', '₹${subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                _buildBillRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                _buildBillRow('Taxes & Charges (5%)', '₹${taxes.toStringAsFixed(0)}'),
                const Divider(height: 30, color: Colors.white10),
                _buildBillRow('Grand Total', '₹${total.toStringAsFixed(0)}', isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: isTotal ? Colors.white : Colors.white54,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isTotal ? const Color(0xFFFA5211) : Colors.white,
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
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
