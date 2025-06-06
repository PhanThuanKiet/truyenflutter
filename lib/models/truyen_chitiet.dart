class TruyenChiTiet {
  final String id;
  final String name;
  final String description;
  final String thumb;
  final List<Map<String, dynamic>> chapters;
  final List<String> theLoai;

  TruyenChiTiet({
    required this.id,
    required this.name,
    required this.description,
    required this.thumb,
    required this.chapters,
    required this.theLoai,
  });

  factory TruyenChiTiet.fromJson(Map<String, dynamic> json, String imgDomain) {
    final item = json['item'];
    String thumb = item['thumb_url'] ?? '';
    if (!thumb.contains('/uploads/comics/')) {
      thumb = '/uploads/comics/$thumb';
    }
    thumb = imgDomain + thumb;

    final List<Map<String, dynamic>> chapters = [];
    if (item['chapters'] != null) {
      for (var server in item['chapters']) {
        if (server['server_data'] != null) {
          for (var chap in server['server_data']) {
            chapters.add(Map<String, dynamic>.from(chap));
          }
        }
      }
    }
    final theLoai = (item['category'] as List?)?.map((e) => e['name']?.toString() ?? '').toList() ?? [];
    return TruyenChiTiet(
      id: item['_id']?.toString() ?? '',
      name: item['name'] ?? '',
      description: item['content'] ?? '',
      thumb: thumb,
      chapters: chapters,
      theLoai: theLoai,
    );
  }
} 