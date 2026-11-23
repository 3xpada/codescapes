import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'achievement.dart';
import 'programming_language.dart';

class GameProgress extends ChangeNotifier {
  static const int puzzleReward = 5;
  static const String _storageKey = 'codescapes.game_progress.v1';

  SharedPreferences? _preferences;
  int _coins = 50; // Starting bonus coins for the player
  final Set<int> _solvedPuzzles = {};
  final Map<int, int> _unlockedHintsCount =
      {}; // puzzleId -> number of hints unlocked
  final Map<String, int> _currentPuzzleIndices = {};
  final Map<String, Set<int>> _solvedPuzzlesByLanguage = {};
  final Set<String> _unlockedAchievementIds = {};
  final Set<String> _newAchievementIds = {};
  int _totalCoinsEarned = 0;
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  int get coins => _coins;
  int get solvedPuzzleCount => _solvedPuzzles.length;
  int get totalHintsUnlocked =>
      _unlockedHintsCount.values.fold(0, (total, count) => total + count);
  int get unlockedAchievementCount => _unlockedAchievementIds.length;
  int get achievementCount => AchievementCatalog.definitions.length;
  int get currentPuzzleIndex =>
      getCurrentPuzzleIndex(ProgrammingLanguage.python);

  int getCurrentPuzzleIndex(ProgrammingLanguage language) =>
      _currentPuzzleIndices[language.name] ?? 0;

  bool isSolved(int puzzleId) => _solvedPuzzles.contains(puzzleId);

  int getUnlockedHints(int puzzleId) => _unlockedHintsCount[puzzleId] ?? 0;

  List<AchievementProgress> get achievements => AchievementCatalog.definitions
      .map(_achievementProgress)
      .toList(growable: false);

  List<AchievementProgress> takeNewlyUnlockedAchievements() {
    final newlyUnlocked = achievements
        .where(
          (achievement) =>
              _newAchievementIds.contains(achievement.definition.id),
        )
        .toList(growable: false);
    _newAchievementIds.clear();
    return newlyUnlocked;
  }

  Future<void> load() {
    if (_isLoaded) return Future<void>.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    final stored = preferences.getString(_storageKey);
    if (stored != null) {
      final data = jsonDecode(stored) as Map<String, dynamic>;
      _coins = data['coins'] as int;
      final savedIndices = data['currentPuzzleIndices'];
      if (savedIndices != null) {
        _currentPuzzleIndices.addAll(
          (savedIndices as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value as int),
          ),
        );
      } else if (data['currentPuzzleIndex'] != null) {
        _currentPuzzleIndices[ProgrammingLanguage.python.name] =
            data['currentPuzzleIndex'] as int;
      }
      _solvedPuzzles
        ..clear()
        ..addAll((data['solvedPuzzles'] as List).cast<int>());
      final savedPuzzlesByLanguage = data['solvedPuzzlesByLanguage'];
      _solvedPuzzlesByLanguage.clear();
      if (savedPuzzlesByLanguage is Map<String, dynamic>) {
        _solvedPuzzlesByLanguage.addAll(
          savedPuzzlesByLanguage.map(
            (language, ids) =>
                MapEntry(language, (ids as List).cast<int>().toSet()),
          ),
        );
      } else {
        for (final puzzleId in _solvedPuzzles) {
          for (final language in ProgrammingLanguage.values) {
            if (language.ownsPuzzleId(puzzleId)) {
              _solvedPuzzlesByLanguage
                  .putIfAbsent(language.name, () => <int>{})
                  .add(puzzleId);
              break;
            }
          }
        }
      }
      _unlockedHintsCount
        ..clear()
        ..addAll(
          (data['unlockedHints'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(int.parse(key), value as int),
          ),
        );
      _totalCoinsEarned =
          data['totalCoinsEarned'] as int? ??
          _solvedPuzzles.length * puzzleReward;
      final savedAchievements = data['unlockedAchievementIds'];
      if (savedAchievements is List) {
        _unlockedAchievementIds
          ..clear()
          ..addAll(savedAchievements.cast<String>());
      }
    }
    _isLoaded = true;
    final achievementsChanged = _unlockEligibleAchievements();
    _newAchievementIds.clear();
    if (achievementsChanged) await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final preferences = _preferences;
    if (!_isLoaded || preferences == null) {
      throw StateError('Load game progress before changing it.');
    }
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode({
        'coins': _coins,
        'currentPuzzleIndices': _currentPuzzleIndices,
        'solvedPuzzles': _solvedPuzzles.toList(),
        'solvedPuzzlesByLanguage': _solvedPuzzlesByLanguage.map(
          (language, ids) => MapEntry(language, ids.toList()),
        ),
        'unlockedHints': _unlockedHintsCount.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        'totalCoinsEarned': _totalCoinsEarned,
        'unlockedAchievementIds': _unlockedAchievementIds.toList(),
      }),
    );
    if (!saved) {
      throw StateError('Unable to save game progress.');
    }
  }

  // Reward coins on first solve
  Future<bool> completePuzzle(
    int puzzleId, {
    ProgrammingLanguage language = ProgrammingLanguage.python,
  }) async {
    _ensureLoaded();
    final isFirstSolve = _solvedPuzzles.add(puzzleId);
    final recordedForLanguage = _solvedPuzzlesByLanguage
        .putIfAbsent(language.name, () => <int>{})
        .add(puzzleId);
    if (isFirstSolve) {
      _coins += puzzleReward;
      _totalCoinsEarned += puzzleReward;
    }
    final achievementsChanged = _unlockEligibleAchievements();
    if (isFirstSolve || recordedForLanguage || achievementsChanged) {
      notifyListeners();
      await _save();
    }
    return isFirstSolve;
  }

  // Buy a hint using coins
  Future<bool> unlockHint(
    int puzzleId,
    int hintCost,
    int maxAvailableHints,
  ) async {
    _ensureLoaded();
    final currentUnlocked = getUnlockedHints(puzzleId);
    if (currentUnlocked >= maxAvailableHints) {
      return false; // All hints unlocked
    }

    if (_coins >= hintCost) {
      _coins -= hintCost;
      _unlockedHintsCount[puzzleId] = currentUnlocked + 1;
      _unlockEligibleAchievements();
      notifyListeners();
      await _save();
      return true;
    }
    return false; // Not enough coins
  }

  Future<void> setCurrentPuzzleIndex(
    int index, {
    ProgrammingLanguage language = ProgrammingLanguage.python,
  }) async {
    _ensureLoaded();
    if (getCurrentPuzzleIndex(language) == index) return;
    _currentPuzzleIndices[language.name] = index;
    notifyListeners();
    await _save();
  }

  Future<void> addCoins(int amount) async {
    _ensureLoaded();
    _coins += amount;
    if (amount > 0) _totalCoinsEarned += amount;
    _unlockEligibleAchievements();
    notifyListeners();
    await _save();
  }

  AchievementProgress _achievementProgress(AchievementDefinition definition) {
    final progress = switch (definition.metric) {
      AchievementMetric.totalPuzzlesSolved => solvedPuzzleCount,
      AchievementMetric.puzzlesSolvedInLanguage =>
        _solvedPuzzlesByLanguage[definition.language!.name]?.length ?? 0,
      AchievementMetric.languagesVisited =>
        _solvedPuzzlesByLanguage.values
            .where((puzzles) => puzzles.isNotEmpty)
            .length,
      AchievementMetric.hintsUnlocked => totalHintsUnlocked,
      AchievementMetric.coinsEarned => _totalCoinsEarned,
    };
    return AchievementProgress(
      definition: definition,
      progress: progress.clamp(0, definition.target).toInt(),
      isUnlocked: _unlockedAchievementIds.contains(definition.id),
    );
  }

  bool _unlockEligibleAchievements() {
    var changed = false;
    for (final achievement in AchievementCatalog.definitions) {
      if (_unlockedAchievementIds.contains(achievement.id)) continue;
      final progress = _achievementProgress(achievement);
      if (progress.progress >= achievement.target) {
        _unlockedAchievementIds.add(achievement.id);
        _newAchievementIds.add(achievement.id);
        changed = true;
      }
    }
    return changed;
  }

  void _ensureLoaded() {
    if (!_isLoaded) {
      throw StateError('Load game progress before changing it.');
    }
  }
}
