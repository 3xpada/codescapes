
import 'package:flutter/material.dart';
import 'screens/loading_screen.dart';
import 'constants/app_colors.dart';

void main() {
  runApp(const CodeScapeApp());
}

class CodeScapeApp extends StatelessWidget {
  const CodeScapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodeScapes',
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundColor,
        useMaterial3: true,
      ),
      home: const LoadingScreen(),
    );
  }
}
