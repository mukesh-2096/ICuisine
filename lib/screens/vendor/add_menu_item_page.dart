import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../config/api_keys.dart';

class AddMenuItemPage extends StatefulWidget {
  const AddMenuItemPage({super.key});

  @override
  State<AddMenuItemPage> createState() => _AddMenuItemPageState();
}

class _AddMenuItemPageState extends State<AddMenuItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _prepTimeController = TextEditingController();
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isTodaySpecial = false;
  String _itemType = 'veg'; // 'veg' or 'non-veg'

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final cloudName = ApiKeys.cloudinaryCloudName.trim();
      final uploadPreset = ApiKeys.cloudinaryUploadPreset.trim();

      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        throw Exception('Cloudinary configuration missing');
      }

      final user = FirebaseAuth.instance.currentUser;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final publicId = 'Menu_Items/${user?.uid}/item_$timestamp';

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
        final jsonMap = jsonDecode(utf8.decode(responseData));
        return jsonMap['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _addItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String? imageUrl;
          if (_imageFile != null) {
            imageUrl = await _uploadImage(_imageFile!);
          }

          await FirebaseFirestore.instance
              .collection('vendors')
              .doc(user.uid)
              .collection('menu')
              .add({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
            'image': imageUrl ?? '',
            'isTodaySpecial': _isTodaySpecial,
            'itemType': _itemType,
            'preparationTime': int.tryParse(_prepTimeController.text.trim()) ?? 15,
            'createdAt': FieldValue.serverTimestamp(),
            'isAvailable': true,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item added successfully!')),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding item: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white38 : Colors.black54;
    final subtextColor2 = isDark ? Colors.white70 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final borderColor = isDark ? Colors.white10 : Colors.black12;
    final hintColor = isDark ? Colors.white24 : Colors.black38;
    final iconDisabledColor = isDark ? Colors.white24 : Colors.black26;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Add Menu Item',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: borderColor),
                      image: _imageFile != null
                          ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 50, color: iconDisabledColor),
                              const SizedBox(height: 12),
                              Text('Add Dish Image', style: GoogleFonts.outfit(color: subtextColor)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel('Item Name', subtextColor2),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration('e.g. Paneer Butter Masala', Icons.restaurant, surfaceColor, borderColor, hintColor),
                validator: (value) => value == null || value.isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 25),
              
              _buildLabel('Description', subtextColor2),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration('Describe your dish...', Icons.description_outlined, surfaceColor, borderColor, hintColor),
                validator: (value) => value == null || value.isEmpty ? 'Please enter description' : null,
              ),
              const SizedBox(height: 25),
              
              _buildLabel('Price (₹)', subtextColor2),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration('0.00', Icons.currency_rupee, surfaceColor, borderColor, hintColor),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter price';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 25),

              _buildLabel('Preparation Time (minutes)', subtextColor2),
              TextFormField(
                controller: _prepTimeController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration('e.g. 15, 30, 45', Icons.timer_outlined, surfaceColor, borderColor, hintColor),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter preparation time';
                  if (int.tryParse(value) == null) return 'Please enter a valid number';
                  if (int.tryParse(value)! <= 0) return 'Time must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 25),

              // Item Type Selector (Veg/Non-Veg)
              _buildLabel('Item Type', subtextColor2),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _itemType = 'veg'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _itemType == 'veg' 
                              ? Colors.green.withOpacity(0.1) 
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _itemType == 'veg' 
                                ? Colors.green 
                                : borderColor,
                            width: _itemType == 'veg' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green, width: 2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Veg',
                              style: GoogleFonts.outfit(
                                color: _itemType == 'veg' ? Colors.green : textColor,
                                fontWeight: _itemType == 'veg' 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _itemType = 'non-veg'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _itemType == 'non-veg' 
                              ? Colors.red.withOpacity(0.1) 
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _itemType == 'non-veg' 
                                ? Colors.red 
                                : borderColor,
                            width: _itemType == 'non-veg' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red, width: 2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Non-Veg',
                              style: GoogleFonts.outfit(
                                color: _itemType == 'non-veg' ? Colors.red : textColor,
                                fontWeight: _itemType == 'non-veg' 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Today's Special Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isTodaySpecial ? const Color(0xFFFA5211).withOpacity(0.1) : surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isTodaySpecial ? const Color(0xFFFA5211).withOpacity(0.5) : borderColor,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: _isTodaySpecial ? const Color(0xFFFA5211) : subtextColor,
                          size: 28,
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Special',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                            ),
                            Text(
                              'Feature this on today\'s list',
                              style: GoogleFonts.outfit(fontSize: 12, color: subtextColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isTodaySpecial,
                      onChanged: (value) {
                        setState(() => _isTodaySpecial = value);
                      },
                      activeColor: const Color(0xFFFA5211),
                      activeTrackColor: const Color(0xFFFA5211).withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFA5211),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Add to Menu',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, Color surfaceColor, Color borderColor, Color hintColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: hintColor, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFFFA5211), size: 20),
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFFA5211), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
