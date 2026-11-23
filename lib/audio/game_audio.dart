import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameSoundEffect { tap, hint, success, error }

extension GameSoundEffectAsset on GameSoundEffect {
  String get assetPath => switch (this) {
    GameSoundEffect.tap => 'audio/tap.wav',
    GameSoundEffect.hint => 'audio/hint.wav',
    GameSoundEffect.success => 'audio/success.wav',
    GameSoundEffect.error => 'audio/error.wav',
  };
}

class GameAudio extends ChangeNotifier with WidgetsBindingObserver {
  static const _musicPreferenceKey = 'codescapes.audio.music';
  static const _effectsPreferenceKey = 'codescapes.audio.effects';
  static const _musicAsset = 'audio/world_theme.wav';

  SharedPreferences? _preferences;
  Future<void>? _initialization;
  AudioPlayer? _musicPlayer;
  AudioPlayer? _effectsPlayer;
  bool _musicEnabled = true;
  bool _effectsEnabled = true;
  bool _gameplayActive = false;
  bool _observingLifecycle = false;

  bool get musicEnabled => _musicEnabled;
  bool get soundEffectsEnabled => _effectsEnabled;

  Future<void> initialize() => _initialization ??= _loadPreferences();

  Future<void> _loadPreferences() async {
    _preferences = await SharedPreferences.getInstance();
    _musicEnabled = _preferences!.getBool(_musicPreferenceKey) ?? true;
    _effectsEnabled = _preferences!.getBool(_effectsPreferenceKey) ?? true;
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
    notifyListeners();
  }

  Future<void> enterGameplay() async {
    await initialize();
    _gameplayActive = true;
    if (_musicEnabled) await _playBackgroundMusic();
  }

  Future<void> leaveGameplay() async {
    _gameplayActive = false;
    final player = _musicPlayer;
    if (player != null) await player.stop();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    await initialize();
    if (_musicEnabled == enabled) return;

    _musicEnabled = enabled;
    notifyListeners();
    await _savePreference(_musicPreferenceKey, enabled);

    if (!enabled) {
      final player = _musicPlayer;
      if (player != null) await player.stop();
    } else if (_gameplayActive) {
      await _playBackgroundMusic();
    }
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    await initialize();
    if (_effectsEnabled == enabled) return;

    _effectsEnabled = enabled;
    notifyListeners();
    await _savePreference(_effectsPreferenceKey, enabled);

    if (!enabled) {
      final player = _effectsPlayer;
      if (player != null) await player.stop();
    }
  }

  Future<void> playEffect(GameSoundEffect effect) async {
    await initialize();
    if (!_effectsEnabled) return;

    final player = _effectsPlayer ??= AudioPlayer(
      playerId: 'codescapes-sound-effects',
    );
    if (player.state == PlayerState.playing) await player.stop();
    await player.play(AssetSource(effect.assetPath), volume: 0.55);
  }

  Future<void> _playBackgroundMusic() async {
    final player = _musicPlayer ??= AudioPlayer(
      playerId: 'codescapes-background-music',
    );
    if (player.state == PlayerState.playing) return;
    if (player.state == PlayerState.paused) {
      await player.resume();
      return;
    }

    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource(_musicAsset), volume: 0.18);
  }

  Future<void> _savePreference(String key, bool value) async {
    final saved = await _preferences!.setBool(key, value);
    if (!saved) throw StateError('Unable to save audio preferences.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_gameplayActive || !_musicEnabled) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_playBackgroundMusic());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      final player = _musicPlayer;
      if (player?.state == PlayerState.playing) unawaited(player!.pause());
    }
  }

  @override
  void dispose() {
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    if (_musicPlayer != null) unawaited(_musicPlayer!.dispose());
    if (_effectsPlayer != null) unawaited(_effectsPlayer!.dispose());
    super.dispose();
  }
}

final GameAudio gameAudio = GameAudio();
