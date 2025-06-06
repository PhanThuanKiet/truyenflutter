class BinhLuan {
  final String id;
  final String username;
  final String content;
  final DateTime createdAt;
  final String chapterId;

  BinhLuan({
    required this.id,
    required this.username,
    required this.content,
    required this.createdAt,
    required this.chapterId,
  });

  factory BinhLuan.fromJson(Map<String, dynamic> json) {
    return BinhLuan(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      chapterId: json['chapter_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'chapter_id': chapterId,
    };
  }
} 