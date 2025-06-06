import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'package:flutter/widgets.dart';

class ReadingProgressService {
  static const String _progressKey = 'reading_progress_';

  static Future<void> saveProgress(String storySlug, String chapterId, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String userKey = 'guest';
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isLoggedIn && authService.username != null) {
        userKey = authService.username!;
      }
    } catch (_) {}
    await prefs.setString(_progressKey + userKey + '_' + storySlug, chapterId);
  }

  static Future<String?> getProgress(String storySlug, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String userKey = 'guest';
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isLoggedIn && authService.username != null) {
        userKey = authService.username!;
      }
    } catch (_) {}
    return prefs.getString(_progressKey + userKey + '_' + storySlug);
  }
} 