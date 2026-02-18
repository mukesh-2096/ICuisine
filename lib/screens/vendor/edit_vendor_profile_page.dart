import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import '../../config/api_keys.dart';
import 'package:google_fonts/google_fonts.dart';

class EditVendorProfilePage extends StatefulWidget {
  final Map<String, dynamic> currentData;

  const EditVendorProfilePage({super.key, required this.currentData});

  @override
  State<EditVendorProfilePage> createState() => _EditVendorProfilePageState();
}

class _EditVendorProfilePageState extends State<EditVendorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _businessNameController;
  late TextEditingController _businessCategoryController;
  late TextEditingController _addressController;
  late TextEditingController _bankAccountController;
  late TextEditingController _upiIdController;
  late TextEditingController _fssaiController;
  
  File? _profileImageFile;
  File? _businessImageFile;
  String? _profileImageUrl;
  String? _businessImageUrl;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.currentData['phone'] ?? '');
    _businessNameController = TextEditingController(text: widget.currentData['businessName'] ?? '');
    _businessCategoryController = TextEditingController(text: widget.currentData['businessCategory'] ?? '');
    _addressController = TextEditingController(text: widget.currentData['address'] ?? '');
    _bankAccountController = TextEditingController(text: widget.currentData['bankAccount'] ?? '');
    _upiIdController = TextEditingController(text: widget.currentData['upiId'] ?? '');
    _fssaiController = TextEditingController(text: widget.currentData['fssai'] ?? '');
    _profileImageUrl = widget.currentData['profileImage'];
    _businessImageUrl = widget.currentData['businessImage'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessCategoryController.dispose();
    _addressController.dispose();
    _bankAccountController.dispose();
    _upiIdController.dispose();
    _fssaiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImageFile = File(pickedFile.path);
          } else {
            _businessImageFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile, bool isProfile, String? oldImageUrl) async {
    try {
      final cloudName = ApiKeys.cloudinaryCloudName.trim();
      final uploadPreset = ApiKeys.cloudinaryUploadPreset.trim();
      final apiKey = ApiKeys.cloudinaryApiKey.trim();
      final apiSecret = ApiKeys.cloudinaryApiSecret.trim();

      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        throw Exception('Cloudinary configuration is missing.');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      if (oldImageUrl != null && oldImageUrl.contains('cloudinary.com')) {
        try {
          final uri = Uri.parse(oldImageUrl);
          final pathSegments = uri.pathSegments;
          int uploadIndex = pathSegments.indexOf('upload');
          if (uploadIndex != -1 && uploadIndex + 2 < pathSegments.length) {
            List<String> publicIdParts = pathSegments.sublist(uploadIndex + 2);
            String oldPublicId = publicIdParts.join('/').split('.').first;
            
            final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
            String paramsToSign = 'public_id=$oldPublicId&timestamp=$timestamp$apiSecret';
            String signature = sha1.convert(utf8.encode(paramsToSign)).toString();

            await http.post(
              Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy'),
              body: {
                'public_id': oldPublicId,
                'api_key': apiKey,
                'timestamp': timestamp,
                'signature': signature,
              },
            );
          }
        } catch (e) {
          debugPrint('DEBUG: Error deleting old image: $e');
        }
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String folder = 'Vendor_Accounts/${user.uid}';
      final String fileName = '${isProfile ? 'profile' : 'business'}_$timestamp';
      final String publicId = '$folder/$fileName';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );
      request.fields['upload_preset'] = uploadPreset;
      request.fields['public_id'] = publicId;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final jsonMap = jsonDecode(String.fromCharCodes(responseData));
        return jsonMap['secure_url'];
      } else {
        throw Exception('Cloudinary upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('DEBUG: Cloudinary Error: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String? newProfileImageUrl = _profileImageUrl;
          String? newBusinessImageUrl = _businessImageUrl;

          if (_profileImageFile != null) {
            newProfileImageUrl = await _uploadToCloudinary(_profileImageFile!, true, _profileImageUrl);
          }

          if (_businessImageFile != null) {
            newBusinessImageUrl = await _uploadToCloudinary(_businessImageFile!, false, _businessImageUrl);
          }

          await FirebaseFirestore.instance.collection('vendors').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'businessName': _businessNameController.text.trim(),
            'businessCategory': _businessCategoryController.text.trim(),
            'address': _addressController.text.trim(),
            'bankAccount': _bankAccountController.text.trim(),
            'upiId': _upiIdController.text.trim(),
            'fssai': _fssaiController.text.trim(),
            if (newProfileImageUrl != null) 'profileImage': newProfileImageUrl,
            if (newBusinessImageUrl != null) 'businessImage': newBusinessImageUrl,
          }, SetOptions(merge: true));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); 
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $e'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final hintColor = isDark ? Colors.white10 : Colors.black26;
    final iconColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? Colors.white10 : Colors.black12;
    final iconDisabledColor = isDark ? Colors.white24 : Colors.black26;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildImagePicker('Profile Image', _profileImageFile, _profileImageUrl, true, surfaceColor, borderColor, iconDisabledColor, textColor)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildImagePicker('Business Image', _businessImageFile, _businessImageUrl, false, surfaceColor, borderColor, iconDisabledColor, textColor)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildTextField('Full Name', _nameController, Icons.person_outline, surfaceColor, hintColor, iconColor, textColor),
                    _buildTextField('Phone Number', _phoneController, Icons.phone_outlined, surfaceColor, hintColor, iconColor, textColor, keyboardType: TextInputType.phone),
                    _buildTextField('Business Name', _businessNameController, Icons.store_outlined, surfaceColor, hintColor, iconColor, textColor),
                    _buildTextField('Business Category', _businessCategoryController, Icons.category_outlined, surfaceColor, hintColor, iconColor, textColor),
                    _buildTextField('Address', _addressController, Icons.location_on_outlined, surfaceColor, hintColor, iconColor, textColor, maxLines: 3),
                    _buildTextField('Bank Account', _bankAccountController, Icons.account_balance_outlined, surfaceColor, hintColor, iconColor, textColor),
                    _buildTextField('UPI ID', _upiIdController, Icons.qr_code_outlined, surfaceColor, hintColor, iconColor, textColor),
                    _buildTextField('FSSAI License', _fssaiController, Icons.verified_user_outlined, surfaceColor, hintColor, iconColor, textColor),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFA5211),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
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
            ),
    );
  }

  Widget _buildImagePicker(String label, File? imageFile, String? imageUrl, bool isProfile, Color surfaceColor, Color borderColor, Color iconDisabledColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickImage(isProfile),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              image: imageFile != null
                  ? DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover)
                  : (imageUrl != null && imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null),
            ),
            child: imageFile == null && (imageUrl == null || imageUrl.isEmpty)
                ? Center(child: Icon(Icons.add_a_photo_outlined, color: iconDisabledColor, size: 32))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, Color surfaceColor, Color hintColor, Color iconColor, Color textColor, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Icon(icon, color: iconColor, size: 20),
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
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
