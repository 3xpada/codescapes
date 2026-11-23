import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/codescape_logo.dart';
import 'home_screen.dart';
import 'registration_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _navigated = false;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener(_onAnimationStatusChanged);
    _controller.forward();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && !_navigated) {
      _navigated = true;
      _openApp();
    }
  }

  Future<void> _openApp() async {
    try {
      await gameProgress.load();
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;

      final username = preferences.getString('player_username');
      final nextScreen = username == null || username.trim().isEmpty
          ? const RegistrationScreen()
          : const CodeScapeHome();
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute<void>(builder: (_) => nextScreen));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _startupError = 'Unable to load saved data: $error';
        _navigated = false;
      });
    }
  }

  void _retryStartup() {
    setState(() {
      _startupError = null;
      _navigated = true;
    });
    _openApp();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onAnimationStatusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoWidth = (constraints.maxWidth - 48)
                  .clamp(0.0, 340.0)
                  .toDouble();
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final progress = _controller.value;
                      const messages = [
                        'INITIALIZING CODE...',
                        'LOADING ASSETS...',
                        'PREPARING YOUR JOURNEY...',
                        'READY!',
                      ];
                      final messageIndex = (progress * messages.length)
                          .floor()
                          .clamp(0, messages.length - 1);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: logoWidth,
                            height: logoWidth * 0.78,
                            child: CodeScapeLogo(
                              darkColor: palette.accent,
                              lightColor: palette.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'THINK. CODE. SOLVE.',
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 11,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 280,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                children: List.generate(
                                  20,
                                  (index) => Expanded(
                                    child: Container(
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      color: index < (progress * 20).floor()
                                          ? palette.accent
                                          : palette.border,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _startupError ?? messages[messageIndex],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 11,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_startupError != null) ...[
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _retryStartup,
                              child: const Text('RETRY'),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
