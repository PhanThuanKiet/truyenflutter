import 'package:flutter/material.dart';
import '../models/truyen_chitiet.dart';
import '../services/api_service.dart';
import '../services/reading_progress_service.dart';
import 'package:flutter_html/flutter_html.dart';
import 'doc_truyen_screen.dart';
import 'doc_truyen_offline_screen.dart';
import '../main.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TruyenChiTietScreen extends StatefulWidget {
  final String slug;
  final bool isYeuThich;
  final VoidCallback onToggleYeuThich;
  const TruyenChiTietScreen({super.key, 
    required this.slug,
    required this.isYeuThich,
    required this.onToggleYeuThich,
  });

  @override
  State<TruyenChiTietScreen> createState() => _TruyenChiTietScreenState();
}

class _TruyenChiTietScreenState extends State<TruyenChiTietScreen> {
  late bool _isYeuThich;
  String? _lastReadChapterId;
  bool _isLoadingProgress = true;
  Map<String, bool> _downloadedChapters = {};
  bool _isDownloadingAll = false;
  double _downloadProgress = 0.0;
  int _currentDownloadingChapter = 0;
  bool _shouldStopDownload = false;

  @override
  void initState() {
    super.initState();
    _isYeuThich = widget.isYeuThich;
    _loadReadingProgress();
    _loadDownloadedChapters();
  }

  Future<void> _loadReadingProgress() async {
    final progress = await ReadingProgressService.getProgress(widget.slug, context);
    setState(() {
      _lastReadChapterId = progress;
      _isLoadingProgress = false;
    });
  }

  Future<void> _loadDownloadedChapters() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final storyDir = Directory('${appDir.path}/${widget.slug}');
      if (await storyDir.exists()) {
        final chapters = await storyDir.list().toList();
        final downloadedChapters = <String, bool>{};
        for (var chapter in chapters) {
          if (chapter is Directory) {
            final chapterId = chapter.path.split('/').last;
            downloadedChapters[chapterId] = true;
          }
        }
        setState(() {
          _downloadedChapters = downloadedChapters;
        });
      }
    } catch (e) {
      print('Error loading downloaded chapters: $e');
    }
  }

  void _handleToggleYeuThich() {
    setState(() {
      _isYeuThich = !_isYeuThich;
    });
    widget.onToggleYeuThich();
  }

  void _navigateToChapter(String chapterId, int chapterIndex, {bool offline = false}) {
    if (offline) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocTruyenOfflineScreen(
            storySlug: widget.slug,
            chapterId: chapterId,
            chapterName: _truyen!.chapters[chapterIndex]['chapter_name'] ?? '',
          ),
        ),
      );
    } else {
      // Add story slug to each chapter data
      final chaptersWithSlug = _truyen!.chapters.map((chapter) {
        return {
          ...chapter,
          'story_slug': widget.slug,
        };
      }).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocTruyenScreen(
            chapterId: chapterId,
            chapters: chaptersWithSlug,
            currentIndex: chapterIndex,
          ),
        ),
      ).then((_) => _loadReadingProgress());
    }
  }

  TruyenChiTiet? _truyen;

  Future<void> _downloadAllChapters() async {
    if (_isDownloadingAll) {
      setState(() {
        _shouldStopDownload = true;
      });
      return;
    }

    setState(() {
      _isDownloadingAll = true;
      _downloadProgress = 0.0;
      _currentDownloadingChapter = 0;
      _shouldStopDownload = false;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final storyDir = Directory('${appDir.path}/${widget.slug}');
      if (!await storyDir.exists()) {
        await storyDir.create(recursive: true);
      }

      // Lưu thông tin truyện
      final truyenData = {
        'id': _truyen!.id,
        'slug': widget.slug,
        'name': _truyen!.name,
        'thumb': _truyen!.thumb,
        'description': _truyen!.description,
        'theLoai': _truyen!.theLoai,
        'chapters': _truyen!.chapters,
      };
      await saveTruyenOffline(widget.slug, truyenData);

      // Tải từng chương
      for (int i = 0; i < _truyen!.chapters.length; i++) {
        if (_shouldStopDownload) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã dừng tải!')),
            );
          }
          break;
        }

        final chapter = _truyen!.chapters[i];
        final chapterId = chapter['chapter_api_data'].split('/').last;
        
        setState(() {
          _currentDownloadingChapter = i;
        });
        
        // Kiểm tra nếu chương đã được tải
        if (_downloadedChapters[chapterId] == true) {
          setState(() {
            _downloadProgress = (i + 1) / _truyen!.chapters.length;
          });
          continue;
        }

        try {
          final chuong = await ApiService.fetchChuong(chapterId);
          final chapterDir = Directory('${storyDir.path}/$chapterId');
          if (!await chapterDir.exists()) {
            await chapterDir.create(recursive: true);
          }

          // Tải từng ảnh trong chương
          for (int j = 0; j < chuong.imageUrls.length; j++) {
            if (_shouldStopDownload) break;
            
            final url = chuong.imageUrls[j];
            final response = await http.get(Uri.parse(url));
            if (response.statusCode == 200) {
              final imageFile = File('${chapterDir.path}/page_$j.jpg');
              await imageFile.writeAsBytes(response.bodyBytes);
            }
          }

          if (_shouldStopDownload) break;

          // Lưu thông tin chương
          final chapterInfo = {
            'chapter_name': chapter['chapter_name'],
            'images': List.generate(chuong.imageUrls.length, (j) => 'page_$j.jpg'),
          };
          final infoFile = File('${chapterDir.path}/info.json');
          await infoFile.writeAsString(jsonEncode(chapterInfo));

          setState(() {
            _downloadedChapters[chapterId] = true;
            _downloadProgress = (i + 1) / _truyen!.chapters.length;
          });
        } catch (e) {
          print('Error downloading chapter $chapterId: $e');
        }
      }

      if (!_shouldStopDownload && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tải xong tất cả chương!')),
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
          _isDownloadingAll = false;
          _shouldStopDownload = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết truyện')),
      body: FutureBuilder<TruyenChiTiet>(
        future: ApiService.fetchTruyenChiTiet(widget.slug),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          _truyen = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                width: double.infinity,
                child: Image.network(
                  _truyen!.thumb,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isYeuThich ? Icons.favorite : Icons.favorite_border,
                      color: _isYeuThich ? Colors.pink : Colors.grey,
                    ),
                    onPressed: _handleToggleYeuThich,
                  ),
                  const SizedBox(width: 8),
                  const Text('Yêu thích'),
                  const SizedBox(width: 16),
                  if (_isDownloadingAll)
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: _downloadProgress,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${(_downloadProgress * 100).toInt()}%'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đang tải chương ${_currentDownloadingChapter + 1}/${_truyen!.chapters.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _downloadAllChapters,
                      icon: Icon(_isDownloadingAll ? Icons.stop : Icons.download),
                      label: Text(_isDownloadingAll ? 'Dừng tải' : 'Tải tất cả chương'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_truyen!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Html(data: _truyen!.description),
              const SizedBox(height: 12),
              Text('Thể loại: ${_truyen!.theLoai.join(', ')}'),
              const SizedBox(height: 16),
              if (!_isLoadingProgress) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_truyen!.chapters.isNotEmpty) {
                          final firstChapter = _truyen!.chapters.first;
                          final chapterId = firstChapter['chapter_api_data'].split('/').last;
                          _navigateToChapter(chapterId, 0);
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Đọc từ đầu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_lastReadChapterId != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          final chapterIndex = _truyen!.chapters.indexWhere(
                            (chapter) => chapter['chapter_api_data'].split('/').last == _lastReadChapterId
                          );
                          if (chapterIndex != -1) {
                            _navigateToChapter(_lastReadChapterId!, chapterIndex);
                          }
                        },
                        icon: const Icon(Icons.bookmark),
                        label: const Text('Đọc tiếp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              const Text('Danh sách chương:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2,
                  ),
                  itemCount: _truyen!.chapters.length,
                  itemBuilder: (context, index) {
                    final chap = _truyen!.chapters[index];
                    final chapterId = chap['chapter_api_data'].split('/').last;
                    final isLastRead = chapterId == _lastReadChapterId;
                    final isDownloaded = _downloadedChapters[chapterId] ?? false;
                    final isDownloading = _isDownloadingAll && index == _currentDownloadingChapter;
                    
                    return GestureDetector(
                      onTap: () => _navigateToChapter(
                        chapterId, 
                        index,
                        offline: isDownloaded,
                      ),
                      child: Card(
                        color: isLastRead ? Colors.blue.withOpacity(0.1) : null,
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                chap['chapter_name'] ?? '',
                                style: TextStyle(
                                  color: isLastRead ? Colors.blue : null,
                                  fontWeight: isLastRead ? FontWeight.bold : null,
                                ),
                              ),
                            ),
                            if (isLastRead)
                              const Positioned(
                                right: 4,
                                top: 4,
                                child: Icon(
                                  Icons.bookmark,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ),
                            if (isDownloaded)
                              const Positioned(
                                left: 4,
                                top: 4,
                                child: Icon(
                                  Icons.download_done,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                            if (isDownloading)
                              const Positioned(
                                left: 4,
                                bottom: 4,
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 