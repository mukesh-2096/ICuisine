import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountSettingsPage extends StatefulWidget {
  final String collectionName;

  const AccountSettingsPage({super.key, this.collectionName = 'users'});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection(widget.collectionName).doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _emailController.text = user.email ?? '';
          _phoneController.text = data?['phone'] ?? '';
        });
      }
    }
  }

  Future<void> _updateAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (_emailController.text.trim() != user.email) {
          try {
            await user.verifyBeforeUpdateEmail(_emailController.text.trim());
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification email sent to new address. Please verify to update.'),
                  backgroundColor: Color(0xFFFA5211),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Email update failed: $e. You may need to re-login.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        }

        await FirebaseFirestore.instance.collection(widget.collectionName).doc(user.uid).update({
          'phone': _phoneController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account details updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating account: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = isDark ? Colors.white10 : Colors.black26;
    final iconColor = isDark ? Colors.white54 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Email Address', textColor),
            _buildTextField(
              controller: _emailController,
              hint: 'Enter email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textColor: textColor,
              hintColor: hintColor,
              iconColor: iconColor,
              surfaceColor: surfaceColor,
            ),
            const SizedBox(height: 24),
            _buildLabel('Phone Number', textColor),
            _buildTextField(
              controller: _phoneController,
              hint: 'Enter phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textColor: textColor,
              hintColor: hintColor,
              iconColor: iconColor,
              surfaceColor: surfaceColor,
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)))
                : SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _updateAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFA5211),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Update Details',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required Color textColor,
    required Color hintColor,
    required Color iconColor,
    required Color surfaceColor,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(icon, color: iconColor),
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFA5211), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
