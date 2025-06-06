import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chuong.dart';

class ChuongService {
  static Future<Chuong> getChuong(String chapterId) async {
    final response = await http.get(
      Uri.parse('https://api.truyen.onl/v2/chapters/$chapterId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Chuong.fromJson(data);
    } else {
      throw Exception('Failed to load chapter');
    }
  }
} 