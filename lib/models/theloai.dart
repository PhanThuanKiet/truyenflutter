class TheLoai {
  final String id;
  final String name;
  final String slug;

  TheLoai({required this.id, required this.name, required this.slug});

  factory TheLoai.fromJson(Map<String, dynamic> json) {
    return TheLoai(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
} 