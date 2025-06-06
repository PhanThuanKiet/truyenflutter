import 'package:flutter/material.dart';
import '../models/truyen.dart';
import '../services/api_service.dart';
import 'truyen_chitiet_screen.dart';

class DanhSachTruyenScreen extends StatelessWidget {
  final String theLoaiSlug;
  final String theLoaiName;
  const DanhSachTruyenScreen({super.key, required this.theLoaiSlug, required this.theLoaiName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(theLoaiName)),
      body: FutureBuilder<List<Truyen>>(
        future: ApiService.fetchTruyenTheoTheLoai(theLoaiSlug, 1),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Lỗi: [snapshot.error]'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final truyens = snapshot.data!;
          return ListView.builder(
            itemCount: truyens.length,
            itemBuilder: (context, index) {
              final truyen = truyens[index];
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
                      ),
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