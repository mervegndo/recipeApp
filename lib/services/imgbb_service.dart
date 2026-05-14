import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ImgBBService {
  static const String _apiKey = '643ba048d6d8913db22e5bd1a2285106';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  // Mobil için (File)
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_uploadUrl?key=$_apiKey'),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      }
      return null;
    } catch (e) {
      debugPrint('ImgBB upload error: $e');
      return null;
    }
  }

  // Web için (Uint8List)
  static Future<String?> uploadImageBytes(Uint8List bytes) async {
    try {
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_uploadUrl?key=$_apiKey'),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      }
      return null;
    } catch (e) {
      debugPrint('ImgBB upload error: $e');
      return null;
    }
  }
}