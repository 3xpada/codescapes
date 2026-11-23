import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../audio/game_audio.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    unawaited(gameAudio.initialize());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: AppBackground(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _sectionTitle('APPEARANCE', palette),
                const SizedBox(height: 12),
                ValueListenableBuilder<AppThemeOption>(
                  valueListenable: appTheme,
                  builder: (context, selectedTheme, _) => Column(
                    children: AppThemeOption.values
                        .map(
                          (option) => _themeTile(
                            option: option,
                            selected: selectedTheme == option,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 28),
                _sectionTitle('SOUND', palette),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: gameAudio,
                  builder: (context, _) => _switchTile(
                    palette: palette,
                    icon: Icons.volume_up_rounded,
                    title: 'Sound effects',
                    subtitle: 'Button sounds and game effects',
                    value: gameAudio.soundEffectsEnabled,
                    onChanged: (value) =>
                        unawaited(gameAudio.setSoundEffectsEnabled(value)),
                  ),
                ),
                ListenableBuilder(
                  listenable: gameAudio,
                  builder: (context, _) => _switchTile(
                    palette: palette,
                    icon: Icons.music_note_rounded,
                    title: 'Background music',
                    subtitle: 'Music during gameplay',
                    value: gameAudio.musicEnabled,
                    onChanged: (value) =>
                        unawaited(gameAudio.setMusicEnabled(value)),
                  ),
                ),
                const SizedBox(height: 28),
                _sectionTitle('ABOUT', palette),
                const SizedBox(height: 12),
                _aboutCard(palette),
                const SizedBox(height: 12),
                _versionCard(palette),
                const SizedBox(height: 28),
                Text(
                  'THINK. CODE. SOLVE.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, AppPalette palette) {
    return Text(
      title,
      style: TextStyle(
        color: palette.muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }

  Widget _themeTile({required AppThemeOption option, required bool selected}) {
    final palette = AppColors.forTheme(option);
    final currentPalette = context.appPalette;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: currentPalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? currentPalette.accent : currentPalette.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => appTheme.value = option,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.bgTop,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Icon(Icons.palette_outlined, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        color: currentPalette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option.description,
                      style: TextStyle(
                        color: currentPalette.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? currentPalette.accent : currentPalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchTile({
    required AppPalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        tileColor: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: Icon(icon, color: palette.accent, size: 23),
        title: Text(
          title,
          style: TextStyle(
            color: palette.text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
        ),
        value: value,
        activeThumbColor: palette.onAccent,
        activeTrackColor: palette.accent,
        inactiveThumbColor: palette.muted,
        inactiveTrackColor: palette.border,
        onChanged: onChanged,
      ),
    );
  }

  Widget _aboutCard(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.code_rounded, color: palette.accent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Codescape',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Explore language worlds through short coding puzzles. Solve levels to earn coins and unlock hints.',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _versionCard(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: palette.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Version', style: TextStyle(color: palette.text)),
          ),
          Text('1.0.0', style: TextStyle(color: palette.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
