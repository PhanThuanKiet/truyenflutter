import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ImageService {
  static const String _imgbbApiKey = '47cdd59a4ce2ce35454c017010847b02'; 
  static const String _imgbbUploadUrl = 'https://api.imgbb.com/1/upload';

  Future<String> uploadImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_imgbbUploadUrl));
      
      // Add image to request
      request.fields['image'] = base64Image;
      request.fields['key'] = _imgbbApiKey;
      
      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      
      if (jsonData['success'] == true) {
        return jsonData['data']['url'];
      } else {
        throw Exception('Upload failed: ${jsonData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> uploadImageFromUrl(String imageUrl) async {
    try {
      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Convert to base64
      final base64Image = base64Encode(response.bodyBytes);
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_imgbbUploadUrl));
      
      // Add image to request
      request.fields['image'] = base64Image;
      request.fields['key'] = _imgbbApiKey;
      
      // Send request
      final uploadResponse = await request.send();
      final responseData = await uploadResponse.stream.bytesToString();
      final jsonData = json.decode(responseData);
      
      if (jsonData['success'] == true) {
        return jsonData['data']['url'];
      } else {
        throw Exception('Upload failed: ${jsonData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
} 