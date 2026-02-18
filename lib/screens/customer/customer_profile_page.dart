import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'my_orders_page.dart';
import 'my_favorites_page.dart';
import 'account_settings_page.dart';
import 'manage_addresses_page.dart';
import '../vendor/settings/theme_settings_page.dart';

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white38 : Colors.black54;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final iconDisabledColor = isDark ? Colors.white24 : Colors.black26;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final borderColor = isDark ? Colors.white10 : Colors.black12;
    final iconBackground = isDark ? Colors.white10 : Colors.black12;
    
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: Text('Please login to view profile', style: TextStyle(color: subtextColor))),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            color: surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: borderColor)),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.settings_outlined, color: textColor, size: 20),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await authService.signOut();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              } else if (value == 'forgot_password') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forgot Password feature coming soon!')));
              } else if (value == 'account_settings') {
                _animatedNav(context, const AccountSettingsPage());
              }
            },
            itemBuilder: (context) => [
              _buildPopupItem('forgot_password', Icons.lock_outline, 'Forgot Password', iconColor, iconColor),
              _buildPopupItem('account_settings', Icons.manage_accounts_outlined, 'Account Settings', iconColor, iconColor),
              const PopupMenuDivider(height: 1),
              _buildPopupItem('logout', Icons.logout, 'Logout', Colors.redAccent, Colors.redAccent),
            ],
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('customers').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final String name = data?['name'] ?? 'User Name';
          final String email = user.email ?? 'user@example.com';
          final String phone = data?['phone'] ?? 'Not provided';
          final String profileImage = data?['profileImage'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Profile Image / Avatar
                GestureDetector(
                  onTap: () {
                    if (profileImage.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(profileImage, fit: BoxFit.contain),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: surfaceColor,
                          border: Border.all(color: const Color(0xFFFA5211), width: 2),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFFA5211).withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                          ],
                        ),
                        child: ClipOval(
                          child: profileImage.isNotEmpty
                              ? Image.network(profileImage, fit: BoxFit.cover)
                              : Icon(Icons.person, size: 60, color: iconBackground),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFFA5211), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Name
                Text(
                  name,
                  style: GoogleFonts.outfit(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Food Lover',
                  style: GoogleFonts.outfit(color: const Color(0xFFFA5211), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                
                const SizedBox(height: 40),
                
                // Details Section
                _buildInfoCard('Email Address', email, Icons.email_outlined, surfaceColor, borderColor, subtextColor, textColor),
                const SizedBox(height: 16),
                _buildInfoCard('Mobile Number', phone, Icons.phone_android_outlined, surfaceColor, borderColor, subtextColor, textColor),
                
                const SizedBox(height: 40),
                
                // Additional List
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildListTile('My Orders', Icons.shopping_bag_outlined, () {
                        _animatedNav(context, const MyOrdersPage());
                      }, iconColor, textColor, iconDisabledColor),
                      Divider(color: borderColor, height: 1),
                      _buildListTile('My Favorites', Icons.favorite_border, () {
                        _animatedNav(context, const MyFavoritesPage());
                      }, iconColor, textColor, iconDisabledColor),
                      Divider(color: borderColor, height: 1),
                      _buildListTile('Addresses', Icons.location_on_outlined, () {
                        _animatedNav(context, const ManageAddressesPage());
                      }, iconColor, textColor, iconDisabledColor),
                      Divider(color: borderColor, height: 1),
                      _buildListTile('Theme', Icons.palette_outlined, () {
                        _animatedNav(context, const ThemeSettingsPage());
                      }, iconColor, textColor, iconDisabledColor),
                      Divider(color: borderColor, height: 1),
                      _buildListTile('Help & Support', Icons.help_outline, () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help & Support coming soon!')));
                      }, iconColor, textColor, iconDisabledColor),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  void _animatedNav(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var trailer = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(trailer),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color surfaceColor, Color borderColor, Color subtextColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFA5211).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFFFA5211), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(color: subtextColor, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap, Color iconColor, Color textColor, Color iconDisabledColor) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: GoogleFonts.outfit(color: textColor, fontSize: 15)),
      trailing: Icon(Icons.chevron_right, color: iconDisabledColor, size: 18),
      onTap: onTap,
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, Color iconColor, Color textColor) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.outfit(color: textColor, fontSize: 14)),
        ],
      ),
    );
  }
}
