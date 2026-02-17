import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth changes
  Stream<User?> get user => _auth.authStateChanges();

  // Sign Up Customer
  Future<UserCredential?> signUpCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save to 'customers' collection
      await _firestore.collection('customers').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Up Vendor
  Future<UserCredential?> signUpVendor({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save to 'vendors' collection
      await _firestore.collection('vendors').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'businessName': businessName,
        'ownerName': ownerName, // This effectively acts as 'name'
        'name': ownerName, // useful to have a common 'name' field
        'phone': phone,
        'role': 'vendor',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      // Check Vendors Collection
      DocumentSnapshot vendorDoc = await _firestore.collection('vendors').doc(uid).get();
      if (vendorDoc.exists) {
        return 'vendor';
      }

      // Check Customers Collection
      DocumentSnapshot customerDoc = await _firestore.collection('customers').doc(uid).get();
      if (customerDoc.exists) {
        return 'customer';
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle(String role) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      // Check existence in both collections
      DocumentSnapshot vendorDoc = await _firestore.collection('vendors').doc(uid).get();
      DocumentSnapshot customerDoc = await _firestore.collection('customers').doc(uid).get();

      if (!vendorDoc.exists && !customerDoc.exists) {
        // New User - Create in appropriate collection based on requested role
        if (role == 'vendor') {
           await _firestore.collection('vendors').doc(uid).set({
            'uid': uid,
            'email': userCredential.user!.email,
            'name': userCredential.user!.displayName ?? '',
            'ownerName': userCredential.user!.displayName ?? '',
            'role': 'vendor',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
           await _firestore.collection('customers').doc(uid).set({
            'uid': uid,
            'email': userCredential.user!.email,
            'name': userCredential.user!.displayName ?? '',
            'role': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
       // ... (Error handling same as before)
      if (e.toString().contains('ApiException: 10')) {
        // ... (Log messages)
        throw Exception('Google Sign-In configuration error.');
      }
      rethrow;
    }
  }
}
