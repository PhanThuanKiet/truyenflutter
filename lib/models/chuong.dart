class Chuong {
  final String title;
  final List<String> imageUrls;

  Chuong({required this.title, required this.imageUrls});

  factory Chuong.fromJson(Map<String, dynamic> json) {
    final domain = json['domain_cdn'];
    final path = json['item']['chapter_path'];
    final images = json['item']['chapter_image'] as List;

    final fullUrls = images.map<String>((img) {
      return "$domain/$path/${img['image_file']}";
    }).toList();

    return Chuong(
      title: json['item']['chapter_title'] ?? 'Chương không tiêu đề',
      imageUrls: fullUrls,
    );
  }
}
