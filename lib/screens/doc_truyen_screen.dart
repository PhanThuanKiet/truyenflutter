import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/reading_progress_service.dart';
import '../models/chuong.dart';
import '../widgets/comment_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DocTruyenScreen extends StatefulWidget {
  final String chapterId;
  final List<Map<String, dynamic>> chapters;
  final int currentIndex;

  const DocTruyenScreen({
    super.key,
    required this.chapterId,
    required this.chapters,
    required this.currentIndex,
  });

  @override
  _DocTruyenScreenState createState() => _DocTruyenScreenState();
}

class _DocTruyenScreenState extends State<DocTruyenScreen> {
  late int _currentIndex;
  late Future<Chuong> _chuong;
  bool _allImagesLoaded = false;
  String _currentUser = 'guest';
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _loadChuong();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUser = prefs.getString('current_user') ?? 'guest';
    });
  }

  void _loadChuong() {
    _allImagesLoaded = false;
    final chapterId = widget.chapters[_currentIndex]['chapter_api_data'].split('/').last;
    _chuong = ApiService.fetchChuong(chapterId);
    _chuong.then((chuong) async {
      // Preload all images
      await Future.wait(chuong.imageUrls.map((url) =>
        precacheImage(NetworkImage(url), context)
      ));
      if (mounted) {
        setState(() {
          _allImagesLoaded = true;
        });
      }
    });
  }

  Future<void> _downloadChapter() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final chuong = await _chuong;
      final chapterId = widget.chapters[_currentIndex]['chapter_api_data'].split('/').last;
      final storySlug = widget.chapters[_currentIndex]['story_slug'];
      
      // Create directory for the story if it doesn't exist
      final appDir = await getApplicationDocumentsDirectory();
      final storyDir = Directory('${appDir.path}/$storySlug');
      if (!await storyDir.exists()) {
        await storyDir.create(recursive: true);
      }

      // Create directory for the chapter
      final chapterDir = Directory('${storyDir.path}/$chapterId');
      if (!await chapterDir.exists()) {
        await chapterDir.create(recursive: true);
      }

      // Download each image
      for (int i = 0; i < chuong.imageUrls.length; i++) {
        final url = chuong.imageUrls[i];
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final imageFile = File('${chapterDir.path}/page_$i.jpg');
          await imageFile.writeAsBytes(response.bodyBytes);
        }
        
        setState(() {
          _downloadProgress = (i + 1) / chuong.imageUrls.length;
        });
      }

      // Save chapter info
      final chapterInfo = {
        'chapter_name': widget.chapters[_currentIndex]['chapter_name'],
        'images': List.generate(chuong.imageUrls.length, (i) => 'page_$i.jpg'),
      };
      final infoFile = File('${chapterDir.path}/info.json');
      await infoFile.writeAsString(jsonEncode(chapterInfo));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tải xong chương!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _changeChuong(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
      _loadChuong();
    });
    // Save reading progress
    final chapterId = widget.chapters[newIndex]['chapter_api_data'].split('/').last;
    ReadingProgressService.saveProgress(
      widget.chapters[0]['story_slug'], 
      chapterId,
      context
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: _currentIndex > 0 ? () => _changeChuong(_currentIndex - 1) : null,
            ),
            Expanded(
              child: DropdownButton<int>(
                value: _currentIndex,
                isExpanded: true,
                items: List.generate(widget.chapters.length, (index) {
                  final chap = widget.chapters[index];
                  return DropdownMenuItem(
                    value: index,
                    child: Text('Chapter ${chap['chapter_name'] ?? ''}'),
                  );
                }),
                onChanged: (value) {
                  if (value != null) _changeChuong(value);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: _currentIndex < widget.chapters.length - 1 ? () => _changeChuong(_currentIndex + 1) : null,
            ),
          ],
        ),
        actions: [
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _downloadProgress,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadChapter,
            ),
        ],
      ),
      body: FutureBuilder<Chuong>(
        future: _chuong,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || !_allImagesLoaded) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else {
            final chuong = snapshot.data!;
            return ListView(
              children: [
                ...chuong.imageUrls.map((url) => Image.network(url)),
                CommentSection(
                  chapterId: widget.chapters[_currentIndex]['chapter_api_data'].split('/').last,
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
