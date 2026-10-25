
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/codescape_logo.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool _navigated = false;

  @override
void initState() {
  super.initState();

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  _controller.addStatusListener((status) {
    if (status == AnimationStatus.completed && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CodeScapeHome(),
        ),
      );
    }
  });

  _controller.forward();
}

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && !_navigated) {
      _navigated = true;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const CodeScapeHome(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;

              final messages = [
                'INITIALIZING CODE...',
                'LOADING ASSETS...',
                'PREPARING YOUR JOURNEY...',
                'READY!',
              ];

              final messageIndex = (progress * messages.length)
                  .floor()
                  .clamp(0, messages.length - 1);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Original CodeScapes logo
                  SizedBox(
                    width: 340,
                    height: 240,
                    child: const CodeScapeLogo(),
                  ),

                  const SizedBox(height: 25),

                  // Tagline
                  const Text(
                    'THINK. CODE. SOLVE.',
                    style: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Pixel loading bar
                  SizedBox(
                    width: 280,
                    child: Row(
                      children: List.generate(20, (index) {
                        final filled = index < (progress * 20).floor();

                        return Expanded(
                          child: Container(
                            height: 12,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 2,
                            ),
                            color: filled
                                ? Colors.white
                                : const Color(0xFF444444),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Loading message
                  Text(
                    messages[messageIndex],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
