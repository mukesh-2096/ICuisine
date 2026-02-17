import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getAuthErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'invalid-email':
          return 'The email address is badly formatted.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'weak-password':
          return 'The password is too weak. Please use a stronger password.';
        case 'operation-not-allowed':
          return 'Email and password login is currently disabled.';
        case 'invalid-credential':
          return 'Invalid email or password. Please check your credentials.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return e.message ?? 'An error occurred. Please try again.';
      }
    }
    
    // For non-Firebase errors, try to return a cleaner string
    String ErrorString = e.toString();
    if (ErrorString.contains('Exception:')) {
      return ErrorString.split('Exception:').last.trim();
    }
    
    return 'An unexpected error occurred: $ErrorString';
  }
}
