// lib/engine/game_progress.dart
import 'package:flutter/foundation.dart';

class GameProgress extends ChangeNotifier {
  static const int puzzleReward = 5;

  int _coins = 50; // Starting bonus coins for the player
  final Set<int> _solvedPuzzles = {};
  final Map<int, int> _unlockedHintsCount = {}; // puzzleId -> number of hints unlocked

  int get coins => _coins;
  
  bool isSolved(int puzzleId) => _solvedPuzzles.contains(puzzleId);

  int getUnlockedHints(int puzzleId) => _unlockedHintsCount[puzzleId] ?? 0;

  // Reward coins on first solve
  bool completePuzzle(int puzzleId) {
    if (!_solvedPuzzles.contains(puzzleId)) {
      _solvedPuzzles.add(puzzleId);
      _coins += puzzleReward;
      notifyListeners();
      return true; // First-time reward granted
    }
    return false; // Already solved before
  }

  // Buy a hint using coins
  bool unlockHint(int puzzleId, int hintCost, int maxAvailableHints) {
    final currentUnlocked = getUnlockedHints(puzzleId);
    if (currentUnlocked >= maxAvailableHints) return false; // All hints unlocked

    if (_coins >= hintCost) {
      _coins -= hintCost;
      _unlockedHintsCount[puzzleId] = currentUnlocked + 1;
      notifyListeners();
      return true;
    }
    return false; // Not enough coins
  }

  void addCoins(int amount) {
    _coins += amount;
    notifyListeners();
  }
}
