import 'package:flutter/material.dart';
import '../models/truyen.dart';

class TruyenCard extends StatelessWidget {
  final Truyen truyen;
  final VoidCallback onTap;

  const TruyenCard({super.key, required this.truyen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.network(truyen.anh, fit: BoxFit.cover),
          ),
          Text(truyen.ten, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
