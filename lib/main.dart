import 'package:flutter/material.dart';

import 'app_state.dart';
import 'theme/app_colors.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CodescapeApp());
}

class CodescapeApp extends StatelessWidget {
  const CodescapeApp({super.key});

  ThemeData _buildTheme(AppThemeOption option) {
    final palette = AppColors.forTheme(option);
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: palette.brightness,
    ).copyWith(
      primary: palette.accent,
      secondary: palette.secondary,
      surface: palette.card,
      error: palette.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.bgTop,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bgTop,
        foregroundColor: palette.text,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: palette.text,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputBg,
        hintStyle: TextStyle(color: palette.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.card,
        contentTextStyle: TextStyle(color: palette.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeOption>(
      valueListenable: appTheme,
      builder: (context, option, _) => MaterialApp(
        title: 'Codescape',
        color: AppColors.forTheme(option).bgTop,
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(option),
        home: const CodeScapeHome(),
      ),
    );
  }
}
