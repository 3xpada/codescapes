import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import 'achievements_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = 'Player';
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedUsername = preferences.getString('player_username');
      if (!mounted) return;
      setState(() {
        _username = savedUsername ?? 'Player';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to load username: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _editUsername() async {
    final controller = TextEditingController(text: _username);
    final newUsername = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final palette = context.appPalette;
        return AlertDialog(
          backgroundColor: palette.card,
          title: Text('EDIT USERNAME', style: TextStyle(color: palette.text)),
          content: TextField(
            controller: controller,
            maxLength: 20,
            autofocus: true,
            style: TextStyle(color: palette.text),
            decoration: const InputDecoration(hintText: 'Enter new username'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Username must be at least 3 characters.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newUsername == null || !mounted) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString('player_username', newUsername);
      if (!saved) {
        throw StateError('The username could not be saved.');
      }
      if (!mounted) return;
      setState(() => _username = newUsername);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save username: $error')),
      );
    }
  }

  Widget _statCard(
    AppPalette palette,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: palette.accent, size: 27),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      appBar: AppBar(title: const Text('PLAYER PROFILE')),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: palette.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.accent, width: 2),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 55,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isLoading ? 'LOADING...' : _username,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'CODESCAPE PLAYER',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_loadError case final error?) ...[
                      const SizedBox(height: 12),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.danger),
                      ),
                      TextButton(
                        onPressed: _loadUsername,
                        child: const Text('RETRY'),
                      ),
                    ],
                    const SizedBox(height: 28),
                    ListenableBuilder(
                      listenable: gameProgress,
                      builder: (context, _) => GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          _statCard(
                            palette,
                            Icons.monetization_on_rounded,
                            'COINS',
                            '${gameProgress.coins}',
                          ),
                          _statCard(
                            palette,
                            Icons.extension_rounded,
                            'PUZZLES COMPLETED',
                            '${gameProgress.solvedPuzzleCount}',
                          ),
                          _statCard(
                            palette,
                            Icons.emoji_events_rounded,
                            'ACHIEVEMENTS',
                            '${gameProgress.unlockedAchievementCount}/${gameProgress.achievementCount}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || _loadError != null
                            ? null
                            : _editUsername,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('EDIT USERNAME'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const AchievementsPage(),
                          ),
                        ),
                        icon: const Icon(Icons.emoji_events_rounded),
                        label: const Text('VIEW ACHIEVEMENTS'),
                      ),
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
