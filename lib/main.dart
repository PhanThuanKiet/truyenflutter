import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/doc_truyen_offline_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Truyện Flutter',
            theme: themeProvider.theme,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

Future<void> saveTruyenOffline(String slug, Map<String, dynamic> truyenData) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$slug.json');
  await file.writeAsString(jsonEncode(truyenData));

  // Lưu danh sách truyện đã tải
  final prefs = await SharedPreferences.getInstance();
  final downloaded = prefs.getStringList('downloaded_truyens') ?? [];
  if (!downloaded.contains(slug)) {
    downloaded.add(slug);
    await prefs.setStringList('downloaded_truyens', downloaded);
  }
}

Future<Map<String, dynamic>?> loadTruyenOffline(String slug) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$slug.json');
  if (await file.exists()) {
    final content = await file.readAsString();
    return jsonDecode(content);
  }
  return null;
}

Future<List<Map<String, dynamic>>> loadAllDownloadedTruyens() async {
  final prefs = await SharedPreferences.getInstance();
  final downloaded = prefs.getStringList('downloaded_truyens') ?? [];
  final dir = await getApplicationDocumentsDirectory();
  List<Map<String, dynamic>> truyens = [];
  for (final slug in downloaded) {
    final file = File('${dir.path}/$slug.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      truyens.add(jsonDecode(content));
    }
  }
  return truyens;
}

class DownloadedTruyenScreen extends StatefulWidget {
  const DownloadedTruyenScreen({super.key});

  @override
  State<DownloadedTruyenScreen> createState() => _DownloadedTruyenScreenState();
}

class _DownloadedTruyenScreenState extends State<DownloadedTruyenScreen> {
  List<Map<String, dynamic>> _truyens = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedTruyens();
  }

  Future<void> _loadDownloadedTruyens() async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList('downloaded_truyens') ?? [];
    final dir = await getApplicationDocumentsDirectory();
    List<Map<String, dynamic>> truyens = [];
    
    for (final slug in downloaded) {
      final file = File('${dir.path}/$slug.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final truyenData = jsonDecode(content);
        
        // Load downloaded chapters
        final storyDir = Directory('${dir.path}/$slug');
        if (await storyDir.exists()) {
          final chapters = await storyDir.list().toList();
          final downloadedChapters = <Map<String, dynamic>>[];
          
          for (var chapter in chapters) {
            if (chapter is Directory) {
              final chapterId = chapter.path.split('/').last;
              final infoFile = File('${chapter.path}/info.json');
              if (await infoFile.exists()) {
                final infoContent = await infoFile.readAsString();
                final info = jsonDecode(infoContent);
                downloadedChapters.add({
                  'chapter_id': chapterId,
                  'chapter_name': info['chapter_name'],
                  'images': info['images'],
                });
              }
            }
          }
          
          truyenData['downloaded_chapters'] = downloadedChapters;
        }
        
        truyens.add(truyenData);
      }
    }
    
    setState(() {
      _truyens = truyens;
      _loading = false;
    });
  }

  Future<void> _deleteStory(String slug) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final storyDir = Directory('${dir.path}/$slug');
      if (await storyDir.exists()) {
        await storyDir.delete(recursive: true);
      }
      
      final file = File('${dir.path}/$slug.json');
      if (await file.exists()) {
        await file.delete();
      }

      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getStringList('downloaded_truyens') ?? [];
      downloaded.remove(slug);
      await prefs.setStringList('downloaded_truyens', downloaded);

      await _loadDownloadedTruyens();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa truyện!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Truyện đã tải')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _truyens.isEmpty
              ? const Center(child: Text('Chưa có truyện nào được tải về!'))
              : ListView.builder(
                  itemCount: _truyens.length,
                  itemBuilder: (context, index) {
                    final truyen = _truyens[index];
                    final downloadedChapters = truyen['downloaded_chapters'] as List<dynamic>? ?? [];
                    
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: truyen['thumb'] != null
                                ? Image.network(
                                    truyen['thumb'],
                                    width: 50,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            title: Text(truyen['name'] ?? truyen['ten'] ?? 'Không tên'),
                            subtitle: Text('${downloadedChapters.length} chương đã tải'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content: const Text('Bạn có chắc muốn xóa truyện này?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteStory(truyen['slug']);
                                        },
                                        child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          if (downloadedChapters.isNotEmpty) ...[
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Các chương đã tải:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: downloadedChapters.map((chapter) {
                                      return ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DocTruyenOfflineScreen(
                                                storySlug: truyen['slug'],
                                                chapterId: chapter['chapter_id'],
                                                chapterName: chapter['chapter_name'],
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(chapter['chapter_name'] ?? ''),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class TruyenOfflineScreen extends StatelessWidget {
  final Map<String, dynamic> truyenData;
  const TruyenOfflineScreen({super.key, required this.truyenData});

  @override
  Widget build(BuildContext context) {
    final chapters = truyenData['chapters'] as List<dynamic>;
    return Scaffold(
      appBar: AppBar(title: Text(truyenData['name'] ?? '')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (truyenData['thumb'] != null)
            SizedBox(
              width: double.infinity,
              child: Image.network(truyenData['thumb'], fit: BoxFit.contain),
            ),
          const SizedBox(height: 12),
          Text(truyenData['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(truyenData['description'] ?? ''),
          const SizedBox(height: 8),
          Text('Thể loại: ${(truyenData['theLoai'] as List<dynamic>).join(', ')}'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: chapters.isNotEmpty
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChuongOfflineScreen(chapter: chapters[0]),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Đọc từ đầu'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Danh sách chương:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...chapters.asMap().entries.map((entry) {
            final index = entry.key;
            final chap = entry.value;
            return ListTile(
              title: Text(chap['chapter_name'] ?? ''),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChuongOfflineScreen(chapter: chap),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class ChuongOfflineScreen extends StatelessWidget {
  final Map<String, dynamic> chapter;
  const ChuongOfflineScreen({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final images = chapter['images'] as List<dynamic>?;
    return Scaffold(
      appBar: AppBar(
        title: Text(chapter['chapter_name'] ?? 'Chương'),
      ),
      body: images != null && images.isNotEmpty
          ? ListView(
              children: [
                ...images.map((url) => Image.network(url, errorBuilder: (c, o, s) => const Text('Không tải được ảnh!'))),
              ],
            )
          : const Center(child: Text('Chưa có nội dung chương!')),
    );
  }
}
