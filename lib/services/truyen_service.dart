import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFFFFCA28), // Vàng ấm
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFFFCA28),
          secondary: const Color(0xFFFFA726), // Cam nhạt
          surface: const Color(0xFFFFF8E1), // Vàng nhạt dự phòng
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF5D4037)), // Nâu nhạt
          bodyMedium: TextStyle(color: Color(0xFF5D4037)),
          headlineLarge: TextStyle(color: Color(0xFF4A322B)), // Nâu đậm
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Trong suốt để dùng gradient
          foregroundColor: Color(0xFF4A322B), // Chữ/icon nâu đậm
          elevation: 0,
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFFFFA726), // Nút cam nhạt
          textTheme: ButtonTextTheme.primary,
        ),
        cardColor: const Color(0xFFFFF3E0), // Card vàng nhạt
        dividerColor: const Color(0xFFE0E0E0),
      ),
      home: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color.fromARGB(100, 255, 183, 76), // Cam vàng nhạt
          BlendMode.softLight, // Mềm mại, giống chế độ bảo vệ mắt
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true, // Cho phép gradient AppBar trong suốt
          appBar: AppBar(
            title: const Text('Eye Protection Gradient Theme'),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFCA28), // Vàng ấm
                    Color(0xFFFFA726), // Cam nhạt
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF8E1), // Vàng nhạt (giống giấy cũ)
                  Color(0xFFFFE0B2), // Cam nhạt
                  Color(0xFFFFCA28), // Vàng ấm
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hello, Gradient Eye Protection Theme!',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Card with eye-friendly colors',
                        style: ThemeData().textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Warm Button'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}