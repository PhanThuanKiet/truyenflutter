import 'package:flutter/material.dart';
import '../models/theloai.dart';
import '../services/api_service.dart';
import 'danh_sach_truyen_screen.dart';

class TheLoaiScreen extends StatelessWidget {
  const TheLoaiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thể loại')),
      body: FutureBuilder<List<TheLoai>>(
        future: ApiService.fetchTheLoai(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Lỗi: [snapshot.error]'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final theloais = snapshot.data!;
          return ListView.builder(
            itemCount: theloais.length,
            itemBuilder: (context, index) {
              final theloai = theloais[index];
              return ListTile(
                title: Text(theloai.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DanhSachTruyenScreen(theLoaiSlug: theloai.slug, theLoaiName: theloai.name),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 