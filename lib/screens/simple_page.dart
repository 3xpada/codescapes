
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SimplePage extends StatelessWidget {
  final String title;
  final String message;

  const SimplePage({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 28, 27, 27),
        foregroundColor: whiteColor,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: whiteColor,
              fontSize: 22,
            ),
          ),
        ),
      ),
    );
  }
}
