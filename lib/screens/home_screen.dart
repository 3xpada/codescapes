
import 'package:flutter/material.dart';
import '../widgets/codescape_logo.dart';
import '../widgets/menu_button.dart';
import 'simple_page.dart';
import 'settings_page.dart';

class CodeScapeHome extends StatelessWidget {
  const CodeScapeHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 38, 37, 37),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 340,
                      height: 290,
                      child: CodeScapeLogo(),
                    ),
                    const SizedBox(height: 35),

                    // PLAY BUTTON
                    MenuButton(
                      icon: Icons.play_arrow,
                      label: 'PLAY',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SimplePage(
                              title: 'PLAY',
                              message: 'Choose your game mode!',
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // DAILY PUZZLE BUTTON
                    MenuButton(
                      icon: Icons.calendar_month,
                      label: 'DAILY PUZZLE',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SimplePage(
                              title: 'DAILY PUZZLE',
                              message: 'Your daily puzzle is coming soon!',
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // SETTINGS BUTTON
                    MenuButton(
                      icon: Icons.settings,
                      label: 'SETTINGS',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                          builder: (_) => SettingsPage(),
                          ),
                        );
                      },
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
}
