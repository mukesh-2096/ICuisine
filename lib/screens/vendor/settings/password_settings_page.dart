import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordSettingsPage extends StatefulWidget {
  const PasswordSettingsPage({super.key});

  @override
  State<PasswordSettingsPage> createState() => _PasswordSettingsPageState();
}

class _PasswordSettingsPageState extends State<PasswordSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null && user.email != null) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _currentPasswordController.text,
          );

          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(_newPasswordController.text);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred.'),
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
  }

  Future<void> _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset email sent to ${user.email}'),
              backgroundColor: const Color(0xFFFA5211),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending reset email: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
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
          'Password Settings',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Current Password', textColor),
              _buildPasswordField(
                controller: _currentPasswordController,
                hint: 'Enter current password',
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter current password' : null,
                textColor: textColor,
                hintColor: hintColor,
                iconColor: iconColor,
                surfaceColor: surfaceColor,
              ),
              const SizedBox(height: 24),
              _buildLabel('New Password', textColor),
              _buildPasswordField(
                controller: _newPasswordController,
                hint: 'Enter new password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (value) => (value == null || value.length < 6)
                    ? 'Password must be at least 6 characters'
                    : null,
                textColor: textColor,
                hintColor: hintColor,
                iconColor: iconColor,
                surfaceColor: surfaceColor,
              ),
              const SizedBox(height: 24),
              _buildLabel('Confirm New Password', textColor),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: 'Confirm new password',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value != _newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
                textColor: textColor,
                hintColor: hintColor,
                iconColor: iconColor,
                surfaceColor: surfaceColor,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)))
                  : SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFA5211),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Update Password',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _resetPassword,
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFA5211),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
    required Color textColor,
    required Color hintColor,
    required Color iconColor,
    required Color surfaceColor,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: surfaceColor,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: iconColor,
          ),
          onPressed: onToggle,
        ),
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
      validator: validator,
    );
  }
}
