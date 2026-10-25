
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool soundEffects = true;
  bool backgroundMusic = true;

  static const Color cardColor = Color(0xFF303030);
  static const Color pageColor = Color(0xFF242424);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: pageColor,
        foregroundColor: whiteColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        children: [
          // SOUND SETTINGS
          _buildSectionTitle('SOUND'),

          const SizedBox(height: 12),

          _buildSwitchTile(
            icon: Icons.volume_up,
            title: 'Sound Effects',
            subtitle: 'Button sounds and game effects',
            value: soundEffects,
            onChanged: (value) {
              setState(() {
                soundEffects = value;
              });
            },
          ),

          _buildSwitchTile(
            icon: Icons.music_note,
            title: 'Background Music',
            subtitle: 'Music during gameplay',
            value: backgroundMusic,
            onChanged: (value) {
              setState(() {
                backgroundMusic = value;
              });
            },
          ),

          const SizedBox(height: 32),

          // ABOUT SECTION
          _buildSectionTitle('ABOUT'),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.code,
                  color: whiteColor,
                  size: 30,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CodeScapes',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'A pixel-style coding puzzle game.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'THINK. CODE. SOLVE.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // VERSION
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white70,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Version',
                    style: TextStyle(
                      color: whiteColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  '1.0.0',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 35),

          const Center(
            child: Text(
              'CODESCAPES',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              'MADE FOR CODING ENTHUSIASTS',
              style: TextStyle(
                color: Colors.white30,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 3,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        secondary: Icon(
          icon,
          color: whiteColor,
          size: 25,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: whiteColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ),
        value: value,
        activeThumbColor: whiteColor,
        activeTrackColor: Colors.white24,
        inactiveThumbColor: Colors.white54,
        inactiveTrackColor: Colors.black26,
        onChanged: onChanged,
      ),
    );
  }
}