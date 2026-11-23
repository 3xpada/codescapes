import 'package:codescapes/audio/game_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('audio settings persist between service instances', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final audio = GameAudio();
    addTearDown(audio.dispose);

    await audio.initialize();
    expect(audio.soundEffectsEnabled, isTrue);
    expect(audio.musicEnabled, isTrue);

    await audio.setSoundEffectsEnabled(false);
    await audio.setMusicEnabled(false);

    final restored = GameAudio();
    addTearDown(restored.dispose);
    await restored.initialize();

    expect(restored.soundEffectsEnabled, isFalse);
    expect(restored.musicEnabled, isFalse);
  });
}
