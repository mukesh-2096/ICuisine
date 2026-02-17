import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/customer/customer_dashboard.dart';
import '../screens/vendor/vendor_dashboard.dart';
import '../screens/landing_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        // If the user is NOT logged in
        if (!snapshot.hasData) {
          return const LandingScreen();
        }

        // If logged in, fetch role and redirect
        return FutureBuilder<String?>(
          future: authService.getUserRole(snapshot.data!.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF121212),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFA5211)),
                ),
              );
            }

            if (roleSnapshot.hasData) {
              if (roleSnapshot.data == 'customer') {
                return const CustomerDashboard();
              } else if (roleSnapshot.data == 'vendor') {
                return const VendorDashboard();
              }
            }

            // Fallback to landing if role not found or error
            return const LandingScreen();
          },
        );
      },
    );
  }
}
