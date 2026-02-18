import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/app_logo.dart';
import 'vendor_dashboard.dart';
import '../../widgets/google_logo.dart';

class VendorSignupPage extends StatefulWidget {
  const VendorSignupPage({super.key});

  @override
  State<VendorSignupPage> createState() => _VendorSignupPageState();
}

class _VendorSignupPageState extends State<VendorSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  final AuthService _authService = AuthService();

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the terms and conditions'),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signUpVendor(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          businessName: _businessNameController.text.trim(),
          ownerName: _ownerNameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
          // Navigate to dashboard and clear stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const VendorDashboard()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorHandler.getAuthErrorMessage(e)),
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

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle('vendor');
      if (result != null && mounted) {
        // Verify role
        String? role = await _authService.getUserRole(result.user!.uid);

        if (mounted) {
          if (role == 'vendor') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Signup successful with Google!')),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const VendorDashboard()),
              (route) => false,
            );
          } else {
            await _authService.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This account is registered as a Customer. Please login as a Customer.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getAuthErrorMessage(e)),
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
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;
    final hintColor = isDark ? Colors.white30 : Colors.black38;
    final iconColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!;
    final checkboxBorderColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        'ICuisine',
                        style: GoogleFonts.outfit(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFA5211),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Digitising Street Food',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: subtextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Center(
                  child: Text(
                    'Create Vendor Account',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Start managing your orders efficiently',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: subtextColor,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Business Name
                _buildLabel('Business Name', textColor),
                TextFormField(
                  controller: _businessNameController,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: _buildInputDecoration('Enter your business name', Icons.business, surfaceColor, hintColor, iconColor),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your business name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Owner Name
                _buildLabel('Owner Name', textColor),
                TextFormField(
                  controller: _ownerNameController,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: _buildInputDecoration('Enter your full name', Icons.person_outline, surfaceColor, hintColor, iconColor),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Email
                _buildLabel('Email Address', textColor),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: _buildInputDecoration('Enter your email', Icons.email_outlined, surfaceColor, hintColor, iconColor),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Phone Number
                _buildLabel('Phone Number', textColor),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: _buildInputDecoration('Enter your phone number', Icons.phone_outlined, surfaceColor, hintColor, iconColor),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password
                _buildLabel('Password', textColor),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: _buildInputDecoration(
                    'Create a password',
                    Icons.lock_outlined,
                    surfaceColor,
                    hintColor,
                    iconColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: iconColor,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Confirm Password
                _buildLabel('Confirm Password', textColor),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: _buildInputDecoration(
                    'Confirm your password',
                    Icons.lock_outlined,
                    surfaceColor,
                    hintColor,
                    iconColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: iconColor,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Terms and Conditions
                Theme(
                  data: ThemeData(unselectedWidgetColor: checkboxBorderColor),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 1.1,
                        child: Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFFFA5211),
                          side: BorderSide(color: checkboxBorderColor, width: 1.5),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'I accept the Terms and Conditions',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: subtextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Signup Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFA5211),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      shadowColor: const Color(0xFFFA5211).withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Create Account',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: borderColor, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'OR',
                        style: GoogleFonts.outfit(
                          color: subtextColor, 
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: borderColor, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 28),

                // Google Signup
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor, width: 1.5),
                      backgroundColor: surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const GoogleLogo(size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Sign up with Google',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.outfit(
                        color: subtextColor, 
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Login',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFA5211),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, Color surfaceColor, Color hintColor, Color iconColor, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      prefixIcon: Icon(icon, color: iconColor, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFA5211), width: 2),
      ),
    );
  }
}
