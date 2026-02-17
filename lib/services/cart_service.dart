import 'package:cloud_firestore/cloud_firestore.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add item to cart
  Future<void> addToCart(String userId, Map<String, dynamic> itemData) async {
    final cartRef = _firestore.collection('customers').doc(userId).collection('cart');
    final docRef = cartRef.doc(itemData['id']);

    final doc = await docRef.get();
    if (doc.exists) {
      // If item already exists, increment quantity
      await docRef.update({
        'quantity': FieldValue.increment(1),
      });
    } else {
      // Add new item
      await docRef.set({
        ...itemData,
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String userId, String itemId) async {
    await _firestore
        .collection('customers')
        .doc(userId)
        .collection('cart')
        .doc(itemId)
        .delete();
  }

  // Update quantity
  Future<void> updateQuantity(String userId, String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(userId, itemId);
    } else {
      await _firestore
          .collection('customers')
          .doc(userId)
          .collection('cart')
          .doc(itemId)
          .update({'quantity': quantity});
    }
  }

  // Clear cart
  Future<void> clearCart(String userId) async {
    final batch = _firestore.batch();
    final cartRef = _firestore.collection('customers').doc(userId).collection('cart');
    final snapshots = await cartRef.get();
    
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Stream of cart items
  Stream<QuerySnapshot> getCartStream(String userId) {
    return _firestore
        .collection('customers')
        .doc(userId)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }
}
