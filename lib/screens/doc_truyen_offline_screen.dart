import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class DocTruyenOfflineScreen extends StatefulWidget {
  final String storySlug;
  final String chapterId;
  final String chapterName;

  const DocTruyenOfflineScreen({
    super.key,
    required this.storySlug,
    required this.chapterId,
    required this.chapterName,
  });

  @override
  State<DocTruyenOfflineScreen> createState() => _DocTruyenOfflineScreenState();
}

class _DocTruyenOfflineScreenState extends State<DocTruyenOfflineScreen> {
  List<String> _imagePaths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapterImages();
  }

  Future<void> _loadChapterImages() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final chapterDir = Directory('${appDir.path}/${widget.storySlug}/${widget.chapterId}');
      
      if (await chapterDir.exists()) {
        final infoFile = File('${chapterDir.path}/info.json');
        if (await infoFile.exists()) {
          final infoContent = await infoFile.readAsString();
          final info = jsonDecode(infoContent);
          final images = info['images'] as List;
          
          setState(() {
            _imagePaths = images.map((img) => '${chapterDir.path}/$img').toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải chương: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapterName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _imagePaths.isEmpty
              ? const Center(child: Text('Không tìm thấy nội dung chương!'))
              : ListView.builder(
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) {
                    return Image.file(
                      File(_imagePaths[index]),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Không tải được ảnh!'),
                        );
                      },
                    );
                  },
                ),
    );
  }
} 