import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chuong.dart';
import '../models/truyen.dart';
import '../models/theloai.dart';
import '../models/truyen_chitiet.dart';

class ApiService {
  static const String baseUrl = 'https://otruyenapi.com/v1/api';

  static Future<List<TheLoai>> fetchTheLoai() async {
  final url = Uri.parse('$baseUrl/the-loai');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final List<dynamic> data = jsonData['data']['items']; 
    return data.map((json) => TheLoai.fromJson(json)).toList();
  } else {
    throw Exception('Không tải được thể loại');
  }
}

  static Future<List<Truyen>> fetchDanhSachTruyenMoi(int page) async {
    final url = Uri.parse('$baseUrl/danh-sach/truyen-moi?page=$page');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> data = jsonData['data']['items'];
      final imgDomain = jsonData['data']['APP_DOMAIN_CDN_IMAGE'] ?? '';
      return data.map<Truyen>((json) => Truyen.fromJson(json, imgDomain)).toList();
    } else {
      throw Exception('Không tải được truyện mới');
    }
  }

  static Future<List<Truyen>> fetchTruyenTheoTheLoai(String slug, int page) async {
    final url = Uri.parse('$baseUrl/the-loai/$slug?page=$page');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> data = jsonData['data']['items'];
      final imgDomain = jsonData['data']['APP_DOMAIN_CDN_IMAGE'] ?? '';
      return data.map<Truyen>((json) => Truyen.fromJson(json, imgDomain)).toList();
    } else {
      throw Exception('Không tải được truyện theo thể loại');
    }
  }

  static Future<TruyenChiTiet> fetchTruyenChiTiet(String slug) async {
    final url = Uri.parse('$baseUrl/truyen-tranh/$slug');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final imgDomain = jsonData['data']['APP_DOMAIN_CDN_IMAGE'] ?? '';
      return TruyenChiTiet.fromJson(jsonData['data'], imgDomain);
    } else {
      throw Exception('Không tải được chi tiết truyện');
    }
  }

  static Future<List<Truyen>> searchTruyen(String keyword) async {
    final url = Uri.parse('$baseUrl/tim-kiem?keyword=$keyword');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> data = jsonData['data']['items'];
      final imgDomain = jsonData['data']['APP_DOMAIN_CDN_IMAGE'] ?? '';
      return data.map<Truyen>((json) => Truyen.fromJson(json, imgDomain)).toList();
    } else {
      throw Exception('Không tìm thấy truyện');
    }
  }

  static Future<Chuong> fetchChuong(String chapterId) async {
    final url = 'https://sv1.otruyencdn.com/v1/api/chapter/$chapterId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Chuong.fromJson(jsonData['data']);
    } else {
      throw Exception('Không tải được chương');
    }
  }
}
