import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  final String cloudName = 'dspvc4fht';
  final String uploadPreset = 'reducer';

  /// Uploads an image to Cloudinary using unsigned preset.
  /// Returns the secure URL of the uploaded image.
  Future<String?> uploadImage(File imageFile, {String? userId}) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // If we want to use specific public_id (e.g. user_uid), we can add it if preset allows override.
      // But unsigned presets usually don't allow setting public_id directly to prevent overwriting other users' files.
      // However, we can use 'folder' or other tags.
      if (userId != null) {
        request.fields['folder'] = 'profile_images/$userId';
        // request.fields['public_id'] = 'profile_$userId'; // Unsigned usually ignores this for security.
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decodedData = json.decode(responseData);
        return decodedData['secure_url'] as String;
      } else {
        debugPrint('CloudinaryService: Upload failed (${response.statusCode}): $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('CloudinaryService: Error: $e');
      return null;
    }
  }
}
