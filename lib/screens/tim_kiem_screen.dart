import 'package:flutter/material.dart';
import '../models/truyen.dart';
import '../services/api_service.dart';
import 'truyen_chitiet_screen.dart';

class TimKiemScreen extends StatefulWidget {
  const TimKiemScreen({super.key});

  @override
  _TimKiemScreenState createState() => _TimKiemScreenState();
}

class _TimKiemScreenState extends State<TimKiemScreen> {
  final _controller = TextEditingController();
  List<Truyen>? _results;
  bool _loading = false;

  void _search() async {
    setState(() { _loading = true; });
    final results = await ApiService.searchTruyen(_controller.text);
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm truyện')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Nhập từ khóa...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                )
              ],
            ),
            if (_loading) const CircularProgressIndicator(),
            if (_results != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    final truyen = _results![index];
                    return ListTile(
                      leading: Image.network(truyen.anh, width: 50, fit: BoxFit.cover),
                      title: Text(truyen.ten),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TruyenChiTietScreen(
                              slug: truyen.slug,
                              isYeuThich: false,
                              onToggleYeuThich: () {},
                            )
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
} 