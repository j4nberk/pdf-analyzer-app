import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/app_view_model.dart';
import 'views/content_view.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppViewModel(),
      child: const PDFAnalyzerApp(),
    ),
  );
}

class PDFAnalyzerApp extends StatelessWidget {
  const PDFAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudySmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFAAC7FF),
          secondary: Color(0xFF74D1FF),
          surface: Color(0xFF131315),
        ),
        scaffoldBackgroundColor: const Color(0xFF131315),
      ),
      home: const ContentView(),
    );
  }
}
