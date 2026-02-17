import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_keys.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_field_page.dart';
import 'settings/password_settings_page.dart';
import 'settings/account_settings_page.dart';

class VendorProfilePage extends StatefulWidget {
  const VendorProfilePage({super.key});

  @override
  State<VendorProfilePage> createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
  final ImagePicker _picker = ImagePicker();
  String? _uploadingTarget; // 'profile' or 'business'

  Future<void> _viewImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(bool isProfile) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          _uploadingTarget = isProfile ? 'profile' : 'business';
        });
        
        File imageFile = File(pickedFile.path);
        final user = FirebaseAuth.instance.currentUser;
        
        if (user == null) return;

        final cloudName = ApiKeys.cloudinaryCloudName.trim();
        final uploadPreset = ApiKeys.cloudinaryUploadPreset.trim();
        final apiKey = ApiKeys.cloudinaryApiKey.trim();
        final apiSecret = ApiKeys.cloudinaryApiSecret.trim();

        if (cloudName.isEmpty || uploadPreset.isEmpty) {
          throw Exception('Cloudinary configuration is missing.');
        }

        final docSnapshot = await FirebaseFirestore.instance.collection('vendors').doc(user.uid).get();
        final String? currentImageUrl = docSnapshot.data()?[isProfile ? 'profileImage' : 'businessImage'];

        if (currentImageUrl != null && currentImageUrl.contains('cloudinary.com')) {
          try {
            final uri = Uri.parse(currentImageUrl);
            final pathSegments = uri.pathSegments;
            int uploadIndex = pathSegments.indexOf('upload');
            if (uploadIndex != -1 && uploadIndex + 2 < pathSegments.length) {
               List<String> publicIdParts = pathSegments.sublist(uploadIndex + 2);
               String publicIdWithExt = publicIdParts.join('/');
               String oldPublicId = publicIdWithExt.split('.').first;
               
               final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
               String paramsToSign = 'public_id=$oldPublicId&timestamp=$timestamp$apiSecret';
               var bytes = utf8.encode(paramsToSign);
               var digest = sha1.convert(bytes);
               String signature = digest.toString();

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
            // Ignore error deleting old image
          }
        }

        final uploadUri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
        final String ts = DateTime.now().millisecondsSinceEpoch.toString();
        final String publicId = 'Vendor_Accounts/${user.uid}/${isProfile ? 'profile' : 'business'}_$ts'; 

        final request = http.MultipartRequest('POST', uploadUri)
          ..fields['upload_preset'] = uploadPreset
          ..fields['public_id'] = publicId
          ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

        final response = await request.send();

        if (response.statusCode == 200) {
          final responseData = await response.stream.toBytes();
          final jsonMap = jsonDecode(utf8.decode(responseData));
          String downloadUrl = jsonMap['secure_url'];

          await FirebaseFirestore.instance.collection('vendors').doc(user.uid).set({
            isProfile ? 'profileImage' : 'businessImage': downloadUrl,
          }, SetOptions(merge: true));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: Colors.green),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingTarget = null);
    }
  }

  void _editField(BuildContext context, String title, List<FieldConfig> fields) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFieldPage(
          title: title, 
          fields: fields,
          collectionName: 'vendors',
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.white70),
              title: Text('Password Settings', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PasswordSettingsPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white70),
              title: Text('Account Settings', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsPage(collectionName: 'vendors')));
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('vendors').doc(user.uid).set({
        'name': _nameController.text.trim(),
      }, SetOptions(merge: true));
      setState(() => _isEditingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(child: Text('Please login to view profile', style: GoogleFonts.outfit(color: Colors.white70))),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Scaffold(backgroundColor: Color(0xFF121212), body: Center(child: Text('Something went wrong')));
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(backgroundColor: Color(0xFF121212), body: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final name = data?['name'] ?? 'Vendor Name';
        final email = user.email ?? 'vendor@example.com';
        final phone = data?['phone'] ?? '+91 XXXXX XXXXX';
        final businessName = data?['businessName'] ?? 'Business Name';
        final businessCategory = data?['businessCategory'] ?? 'Category';
        final address = data?['address'] ?? 'Address Not Set';
        final bankAccount = data?['bankAccount'] ?? 'Not Set';
        final upiId = data?['upiId'] ?? 'Not Set';
        final hours = data?['hours'] ?? '10:00 AM - 10:00 PM';
        final fssai = data?['fssai'] ?? 'Not Set';
        final terms = data?['terms'] ?? 'View Details';
        final profileImage = data?['profileImage'];
        final businessImage = data?['businessImage'];

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: Text('Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
            actions: [
              if (_uploadingTarget != null)
                const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
              IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: () => _showSettings(context)),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: () => _viewImage(profileImage),
                            child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E1E1E),
                                border: Border.all(color: const Color(0xFFFA5211), width: 3),
                                boxShadow: [BoxShadow(color: const Color(0xFFFA5211).withOpacity(0.2), blurRadius: 15)],
                              ),
                              child: ClipOval(
                                child: (profileImage != null && profileImage.isNotEmpty)
                                    ? Image.network(profileImage, fit: BoxFit.cover)
                                    : const Icon(Icons.person, size: 60, color: Colors.white10),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _pickAndUploadImage(true),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFFFA5211), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _isEditingName
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 200,
                                  child: TextField(
                                    controller: _nameController,
                                    autofocus: true,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                    decoration: const InputDecoration(enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFA5211)))),
                                  ),
                                ),
                                IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _saveName),
                                IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), onPressed: () => setState(() => _isEditingName = false)),
                              ],
                            )
                          : GestureDetector(
                              onTap: () { _nameController.text = name; setState(() => _isEditingName = true); },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(name, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.edit_outlined, size: 16, color: Colors.white38),
                                ],
                              ),
                            ),
                      const SizedBox(height: 8),
                      Text(email, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(phone, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                _buildSectionHeader('Business Details', () {
                   showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(leading: const Icon(Icons.edit_outlined, color: Colors.white70), title: Text('Edit Details', style: GoogleFonts.outfit(color: Colors.white)), onTap: () {
                            Navigator.pop(context);
                            _editField(context, 'Business Info', [
                              FieldConfig(key: 'businessName', label: 'Business Name', currentValue: businessName),
                              FieldConfig(key: 'businessCategory', label: 'Category', currentValue: businessCategory),
                            ]);
                          }),
                          ListTile(leading: const Icon(Icons.image_outlined, color: Colors.white70), title: Text('Change Business Image', style: GoogleFonts.outfit(color: Colors.white)), onTap: () { Navigator.pop(context); _pickAndUploadImage(false); }),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _viewImage(businessImage),
                            child: Container(
                              width: 65, height: 65,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.white.withOpacity(0.05)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: (businessImage != null && businessImage.isNotEmpty)
                                    ? Image.network(businessImage, fit: BoxFit.cover)
                                    : const Icon(Icons.store, color: Colors.white24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(businessName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text(businessCategory, style: GoogleFonts.outfit(color: Colors.white38)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Details', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white38), onPressed: () => _editField(context, 'Payment Details', [
                            FieldConfig(key: 'bankAccount', label: 'Bank Account', currentValue: bankAccount),
                            FieldConfig(key: 'upiId', label: 'UPI ID', currentValue: upiId),
                          ])),
                        ],
                      ),
                      _buildPaymentInfoRow(Icons.account_balance_outlined, 'Bank Account', bankAccount),
                      const SizedBox(height: 15),
                      _buildPaymentInfoRow(Icons.qr_code_outlined, 'UPI ID', upiId),
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                Text('More Details', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                  child: Column(
                    children: [
                      _buildListTile(context, Icons.location_on_outlined, 'Address', address, 'address', inputType: TextInputType.streetAddress, maxLines: 3),
                      _buildDivider(),
                      _buildListTile(context, Icons.access_time_outlined, 'Opening Hours', hours, 'hours'), 
                      _buildDivider(),
                      _buildListTile(context, Icons.verified_user_outlined, 'FSSAI License', fssai, 'fssai'),
                      _buildDivider(),
                      _buildListTile(context, Icons.description_outlined, 'Terms & Policies', terms, 'terms', inputType: TextInputType.multiline, maxLines: 5),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white38), onPressed: onEdit),
      ],
    );
  }

  Widget _buildDivider() => const Divider(color: Colors.white10, height: 1);

  Widget _buildPaymentInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFA5211).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFFFA5211), size: 18),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, String? value, String key, {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    String displayValue = (value == null || value.isEmpty || value == 'Address Not Set' || value == 'Not Set') ? 'Tap to Add' : value;
    bool isMissing = (value == null || value.isEmpty || value == 'Address Not Set' || value == 'Not Set');

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFFA5211).withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFFFA5211), size: 18),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15)),
      subtitle: Text(displayValue, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: isMissing ? const Color(0xFFFA5211) : Colors.white38, fontSize: 13)),
      trailing: Icon(isMissing ? Icons.add_circle_outline : Icons.chevron_right, size: 18, color: isMissing ? const Color(0xFFFA5211) : Colors.white24),
      onTap: () => _editField(context, title, [FieldConfig(key: key, label: title, currentValue: isMissing ? '' : value!, inputType: inputType, maxLines: maxLines)]),
    );
  }
}
