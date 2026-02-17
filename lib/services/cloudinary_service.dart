import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../config/api_keys.dart';

class CloudinaryService {
  static Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    required String fileName,
    String? oldImageUrl,
  }) async {
    try {
      final cloudName = ApiKeys.cloudinaryCloudName.trim();
      final uploadPreset = ApiKeys.cloudinaryUploadPreset.trim();
      final apiKey = ApiKeys.cloudinaryApiKey.trim();
      final apiSecret = ApiKeys.cloudinaryApiSecret.trim();

      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        throw Exception('Cloudinary configuration is missing.');
      }

      // 1. Delete old image if it exists
      if (oldImageUrl != null && oldImageUrl.contains('cloudinary.com')) {
        await deleteImage(oldImageUrl);
      }

      // 2. Upload new image
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
      print('DEBUG: Cloudinary Upload Error: $e');
      return null;
    }
  }

  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final cloudName = ApiKeys.cloudinaryCloudName.trim();
      final apiKey = ApiKeys.cloudinaryApiKey.trim();
      final apiSecret = ApiKeys.cloudinaryApiSecret.trim();

      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      int uploadIndex = pathSegments.indexOf('upload');
      
      if (uploadIndex != -1 && uploadIndex + 2 < pathSegments.length) {
        List<String> publicIdParts = pathSegments.sublist(uploadIndex + 2);
        String publicId = publicIdParts.join('/').split('.').first;
        
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String paramsToSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
        String signature = sha1.convert(utf8.encode(paramsToSign)).toString();

        final response = await http.post(
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy'),
          body: {
            'public_id': publicId,
            'api_key': apiKey,
            'timestamp': timestamp,
            'signature': signature,
          },
        );

        return response.statusCode == 200;
      }
      return false;
    } catch (e) {
      print('DEBUG: Cloudinary Delete Error: $e');
      return false;
    }
  }
}
