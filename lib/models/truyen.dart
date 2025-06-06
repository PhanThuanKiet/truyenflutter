class Truyen {
  final String id;
  final String slug;
  final String ten;
  final String anh;
  final String chapterId;
  final List<String> theLoai;

  Truyen({
    required this.id,
    required this.slug,
    required this.ten,
    required this.anh,
    required this.chapterId,
    required this.theLoai,
  });

  factory Truyen.fromJson(Map<String, dynamic> json, String imgDomain) {
    final id = json['_id']?.toString() ?? '';
    final slug = json['slug'] ?? '';
    final ten = json['name'] ?? 'Không tên';
    // Sửa đường dẫn ảnh: nếu thumb_url đã có '/uploads/comics/' thì giữ nguyên, nếu không thì thêm vào
    String thumb = json['thumb_url'] ?? '';
    if (!thumb.contains('/uploads/comics/')) {
      thumb = '/uploads/comics/$thumb';
    }
    var anh = imgDomain + thumb;
    // Nếu domain là img.otruyenapi.com mà ảnh lỗi, có thể thử thay bằng img.otruyencdn.com (tuỳ chọn fallback)
    // Lấy id chương mới nhất
    String chapterId = '';
    if (json['chaptersLatest'] != null && json['chaptersLatest'].isNotEmpty) {
      final chapterApi = json['chaptersLatest'][0]['chapter_api_data'] as String?;
      if (chapterApi != null && chapterApi.isNotEmpty) {
        final parts = chapterApi.split('/');
        chapterId = parts.isNotEmpty ? parts.last : '';
      }
    }
    final theLoai = (json['category'] as List?)?.map((e) => e['name']?.toString() ?? '').where((e) => e.isNotEmpty).toList() ?? [];
    return Truyen(
      id: id,
      slug: slug,
      ten: ten,
      anh: anh,
      chapterId: chapterId,
      theLoai: theLoai,
    );
  }
}
