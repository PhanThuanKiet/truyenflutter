import 'package:flutter/material.dart';
import '../models/truyen.dart';
import 'truyen_chitiet_screen.dart';
import '../widgets/truyen_card.dart';
import '../models/theloai.dart';
import '../services/api_service.dart';
import 'tim_kiem_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../main.dart';

class YeuThichStorage {
  static Future<void> saveYeuThich(String username, List<String> slugs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('yeuthich_$username', slugs);
  }

  static Future<List<String>> loadYeuThich(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('yeuthich_$username') ?? [];
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TheLoai> _theLoais = [];
  TheLoai? _selectedTheLoai;
  List<Truyen> _truyens = [];
  bool _loadingTruyen = false;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  List<String> _yeuThichSlugs = [];
  String _currentUser = 'guest';

  @override
  void initState() {
    super.initState();
    _fetchTheLoai();
    _fetchTruyenMoi(reset: true);
    _loadYeuThich();
    _scrollController.addListener(_onScroll);
  }

  void _fetchTheLoai() async {
    final theloais = await ApiService.fetchTheLoai();
    setState(() {
      _theLoais = theloais;
    });
  }

  void _fetchTruyenMoi({bool reset = false}) async {
    setState(() { _loadingTruyen = true; });
    final page = reset ? 1 : _currentPage + 1;
    final truyens = await ApiService.fetchDanhSachTruyenMoi(page);
    setState(() {
      if (reset) {
        _truyens = truyens;
        _currentPage = 1;
      } else {
        _truyens.addAll(truyens);
        _currentPage = page;
      }
      _hasMore = truyens.isNotEmpty;
      _loadingTruyen = false;
    });
  }

  void _fetchTruyenTheoTheLoai(TheLoai theLoai, {bool reset = false}) async {
    setState(() { _loadingTruyen = true; });
    final page = reset ? 1 : _currentPage + 1;
    final truyens = await ApiService.fetchTruyenTheoTheLoai(theLoai.slug, page);
    setState(() {
      if (reset) {
        _truyens = truyens;
        _currentPage = 1;
      } else {
        _truyens.addAll(truyens);
        _currentPage = page;
      }
      _hasMore = truyens.isNotEmpty;
      _loadingTruyen = false;
    });
  }

  void _onLoadMore() {
    if (_selectedTheLoai == null) {
      _fetchTruyenMoi();
    } else {
      _fetchTruyenTheoTheLoai(_selectedTheLoai!);
    }
  }

  void _onTheLoaiChanged(TheLoai? theloai) {
    setState(() { _selectedTheLoai = theloai; });
    if (theloai == null) {
      _fetchTruyenMoi(reset: true);
    } else {
      _fetchTruyenTheoTheLoai(theloai, reset: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_loadingTruyen) {
        _onLoadMore();
      }
    }
  }

  Future<void> _loadYeuThich() async {
    final slugs = await YeuThichStorage.loadYeuThich(_currentUser);
    setState(() {
      _yeuThichSlugs = slugs;
    });
  }

  Future<void> _saveYeuThich() async {
    await YeuThichStorage.saveYeuThich(_currentUser, _yeuThichSlugs);
  }

  void _toggleYeuThich(Truyen truyen) async {
    setState(() {
      if (_yeuThichSlugs.contains(truyen.slug)) {
        _yeuThichSlugs.remove(truyen.slug);
      } else {
        _yeuThichSlugs.add(truyen.slug);
      }
    });
    await _saveYeuThich();
  }

  void _showYeuThich() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Truyện yêu thích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (_yeuThichSlugs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có truyện nào!'),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _yeuThichSlugs.length,
                    itemBuilder: (context, index) {
                      final slug = _yeuThichSlugs[index];
                      final truyen = _truyens.firstWhere(
                        (t) => t.slug == slug,
                        orElse: () => Truyen(
                          id: '',
                          slug: slug,
                          ten: '',
                          anh: '',
                          chapterId: '',
                          theLoai: [],
                        ),
                      );
                      if (truyen.ten == '') {
                        return const SizedBox.shrink();
                      }
                      return Stack(
                        children: [
                          truyen == null
                              ? const CircularProgressIndicator()
                              : TruyenCard(
                                  truyen: truyen,
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TruyenChiTietScreen(
                                          slug: truyen.slug,
                                          isYeuThich: _yeuThichSlugs.contains(truyen.slug),
                                          onToggleYeuThich: () => _toggleYeuThich(truyen),
                                        ),
                                      ),
                                    ).then((_) => setState(() {}));
                                  },
                                ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _toggleYeuThich(truyen),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
      isScrollControlled: true,
    );
  }

  void _showLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onLogin: (email) async {
            setState(() {
              _currentUser = email;
            });
            await _loadYeuThich();
          },
        ),
      ),
    );
  }

  void _logout() async {
    setState(() {
      _currentUser = 'guest';
    });
    await _loadYeuThich();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng xuất!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 Truyện Online"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TimKiemScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('Lọc thể loại: '),
                Expanded(
                  child: DropdownButton<TheLoai>(
                    value: _selectedTheLoai,
                    hint: const Text('Tất cả'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<TheLoai>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      ..._theLoais.map((theloai) => DropdownMenuItem<TheLoai>(
                        value: theloai,
                        child: Text(theloai.name),
                      ))
                    ],
                    onChanged: _onTheLoaiChanged,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingTruyen && _truyens.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _truyens.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _truyens.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _loadingTruyen
                                      ? const CircularProgressIndicator()
                                      : const Text(''),
                                ),
                              );
                            }
                            final truyen = _truyens[index];
                            final isYeuThich = _yeuThichSlugs.contains(truyen.slug);
                            return Stack(
                              children: [
                                TruyenCard(
                                  truyen: truyen,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TruyenChiTietScreen(
                                          slug: truyen.slug,
                                          isYeuThich: _yeuThichSlugs.contains(truyen.slug),
                                          onToggleYeuThich: () => _toggleYeuThich(truyen),
                                        ),
                                      ),
                                    ).then((_) => setState(() {}));
                                  },
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: Icon(
                                      isYeuThich ? Icons.favorite : Icons.favorite_border,
                                      color: isYeuThich ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () => _toggleYeuThich(truyen),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Yêu thích'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Tải truyện'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
        onTap: (index) {
          if (index == 0) {
            _showYeuThich();
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DownloadedTruyenScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  onLogout: () async {
                    setState(() {
                      _currentUser = 'guest';
                    });
                    await _loadYeuThich();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng xuất!')));
                  },
                  onLogin: (email) async {
                    setState(() {
                      _currentUser = email;
                    });
                    await _loadYeuThich();
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        children: [
          if (truyenData['thumb'] != null)
            Image.network(truyenData['thumb']),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(truyenData['description'] ?? ''),
          ),
          const Divider(),
          const Text('Danh sách chương:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...chapters.map((chap) => ListTile(
                title: Text(chap['chapter_name'] ?? ''),
                // TODO: Hiển thị nội dung chương offline nếu đã lưu
              )),
        ],
      ),
    );
  }
}
