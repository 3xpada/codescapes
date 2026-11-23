import 'package:flutter/material.dart';

enum AppThemeOption { cyber, violet, daylight }

extension AppThemeOptionLabel on AppThemeOption {
  String get label => switch (this) {
    AppThemeOption.cyber => 'Cyber',
    AppThemeOption.violet => 'Violet',
    AppThemeOption.daylight => 'Daylight',
  };

  String get description => switch (this) {
    AppThemeOption.cyber => 'Soft teal accents on a muted slate backdrop',
    AppThemeOption.violet => 'A vivid purple night palette',
    AppThemeOption.daylight => 'A bright, easy-on-the-eyes palette',
  };
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.border,
    required this.inputBg,
    required this.text,
    required this.muted,
    required this.accent,
    required this.secondary,
    required this.success,
    required this.onAccent,
    required this.warning,
    required this.danger,
  });

  final Brightness brightness;
  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color border;
  final Color inputBg;
  final Color text;
  final Color muted;
  final Color accent;
  final Color secondary;
  final Color success;
  final Color onAccent;
  final Color warning;
  final Color danger;

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? bgTop,
    Color? bgBottom,
    Color? card,
    Color? border,
    Color? inputBg,
    Color? text,
    Color? muted,
    Color? accent,
    Color? secondary,
    Color? success,
    Color? onAccent,
    Color? warning,
    Color? danger,
  }) => AppPalette(
    brightness: brightness ?? this.brightness,
    bgTop: bgTop ?? this.bgTop,
    bgBottom: bgBottom ?? this.bgBottom,
    card: card ?? this.card,
    border: border ?? this.border,
    inputBg: inputBg ?? this.inputBg,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    accent: accent ?? this.accent,
    secondary: secondary ?? this.secondary,
    success: success ?? this.success,
    onAccent: onAccent ?? this.onAccent,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

class AppColors {
  static const cyber = AppPalette(
    brightness: Brightness.dark,
    bgTop: Color(0xFF10171F),
    bgBottom: Color(0xFF151E28),
    card: Color(0xFF1A2530),
    border: Color(0xFF32404B),
    inputBg: Color(0xFF111922),
    text: Color(0xFFE2E8EC),
    muted: Color(0xFF9AA7B1),
    accent: Color(0xFF83B9BB),
    secondary: Color(0xFFA79CBF),
    success: Color(0xFF8FB7A0),
    onAccent: Color(0xFF122022),
    warning: Color(0xFFD7B881),
    danger: Color(0xFFD88E8E),
  );

  static const violet = AppPalette(
    brightness: Brightness.dark,
    bgTop: Color(0xFF100B1D),
    bgBottom: Color(0xFF17102A),
    card: Color(0xFF201733),
    border: Color(0xFF3A2B55),
    inputBg: Color(0xFF160F25),
    text: Color(0xFFF1EAFE),
    muted: Color(0xFFAA9CC4),
    accent: Color(0xFFC4A1FF),
    secondary: Color(0xFF8B7BFF),
    success: Color(0xFF68DDB2),
    onAccent: Color(0xFF211332),
    warning: Color(0xFFFFC46B),
    danger: Color(0xFFFF8B9B),
  );

  static const daylight = AppPalette(
    brightness: Brightness.light,
    bgTop: Color(0xFFF7FAFF),
    bgBottom: Color(0xFFEAF0F8),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFD9E2EF),
    inputBg: Color(0xFFF1F5FA),
    text: Color(0xFF17243A),
    muted: Color(0xFF66758B),
    accent: Color(0xFF087F8C),
    secondary: Color(0xFF6457C8),
    success: Color(0xFF16845B),
    onAccent: Color(0xFFFFFFFF),
    warning: Color(0xFF9A5B00),
    danger: Color(0xFFB4233C),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? cyber;

  static AppPalette forTheme(AppThemeOption option) => switch (option) {
    AppThemeOption.cyber => cyber,
    AppThemeOption.violet => violet,
    AppThemeOption.daylight => daylight,
  };
}

extension AppPaletteContext on BuildContext {
  AppPalette get appPalette => AppColors.of(this);
}
