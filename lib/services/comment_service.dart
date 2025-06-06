import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/binh_luan.dart';

class CommentService {
  static const String _commentsKey = 'comments_';

  static Future<List<BinhLuan>> getComments(String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    final commentsJson = prefs.getStringList(_commentsKey + chapterId) ?? [];
    return commentsJson
        .map((json) => BinhLuan.fromJson(jsonDecode(json)))
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by newest first
  }

  static Future<void> addComment(String chapterId, String email, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final comments = await getComments(chapterId);
    
    final newComment = BinhLuan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: email,
      content: content,
      createdAt: DateTime.now(),
      chapterId: chapterId,
    );
    
    comments.add(newComment);
    
    final commentsJson = comments
        .map((comment) => jsonEncode(comment.toJson()))
        .toList();
    
    await prefs.setStringList(_commentsKey + chapterId, commentsJson);
  }

  static Future<void> deleteComment(String chapterId, String commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final comments = await getComments(chapterId);
    
    comments.removeWhere((comment) => comment.id == commentId);
    
    final commentsJson = comments
        .map((comment) => jsonEncode(comment.toJson()))
        .toList();
    
    await prefs.setStringList(_commentsKey + chapterId, commentsJson);
  }
} 