import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../audio/game_audio.dart';
import '../engine/achievement.dart';
import '../widgets/app_background.dart';
import '../theme/app_colors.dart';
import '../engine/game_progress_manager.dart';
import '../engine/puzzle.dart';
import '../engine/programming_language.dart';
import '../widgets/code_bot_mascot.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, this.language = ProgrammingLanguage.python});

  final ProgrammingLanguage language;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with SingleTickerProviderStateMixin {
  static const double _gap = 12;
  static const double _pagePad = 16;

  List<Puzzle> _puzzles = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _loadError;
  final GameProgress _progress = gameProgress; // shared app-wide

  final List<TextEditingController> _controllers = [];
  String _mascotMessage = "I'm Byte. Let's solve this level together.";
  String? _pinnedMascotHint;
  bool _showMascotBubble = false;
  Timer? _mascotBubbleTimer;
  late final AnimationController _mascotFloatController;
  late final Animation<double> _mascotFloatOffset;
  bool _isExecuting = false;
  AppPalette get _palette => context.appPalette;

  @override
  void initState() {
    super.initState();
    unawaited(gameAudio.enterGameplay());
    _mascotFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _mascotFloatOffset = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _mascotFloatController, curve: Curves.easeInOut),
    );
    _loadPuzzles();
  }

  @override
  void dispose() {
    _mascotBubbleTimer?.cancel();
    _mascotFloatController.dispose();
    unawaited(gameAudio.leaveGameplay());
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPuzzles() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final jsonString = await rootBundle.loadString(widget.language.assetPath);
      final data = jsonDecode(jsonString);
      final list = (data['puzzles'] as List)
          .map((j) => Puzzle.fromJson(j as Map<String, dynamic>))
          .toList();
      await _progress.load();
      if (!mounted) return;
      if (list.isNotEmpty) {
        final savedIndex = _progress.getCurrentPuzzleIndex(widget.language);
        final restoredIndex = savedIndex.clamp(0, list.length - 1).toInt();
        if (restoredIndex != savedIndex) {
          await _progress.setCurrentPuzzleIndex(
            restoredIndex,
            language: widget.language,
          );
        }
        _currentIndex = restoredIndex;
      }
      setState(() {
        _puzzles = list;
        _isLoading = false;
        _initControllers();
      });
      if (list.isNotEmpty) {
        _say(_mascotMessage, persistent: _pinnedMascotHint != null);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error is MissingPluginException
            ? 'Local saves need a full app restart after adding the storage plugin. Stop the app completely, then run it again; hot reload cannot install native plugins.'
            : 'Unable to load game data: $error';
      });
    }
  }

  void _initControllers() {
    for (var c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    if (_puzzles.isNotEmpty) {
      final puzzle = _puzzles[_currentIndex];
      for (int i = 0; i < puzzle.blankCount; i++) {
        _controllers.add(TextEditingController());
      }
      final hintsCount = _progress
          .getUnlockedHints(puzzle.id)
          .clamp(0, puzzle.hints.length)
          .toInt();
      _pinnedMascotHint = hintsCount == 0 ? null : puzzle.hints[hintsCount - 1];
      _mascotMessage =
          _pinnedMascotHint ?? "I'm Byte. Let's solve this level together.";
    }
  }

  void _runCode() {
    if (_puzzles.isEmpty) return;
    FocusScope.of(context).unfocus();
    unawaited(gameAudio.playEffect(GameSoundEffect.tap));
    setState(() {
      _isExecuting = true;
    });

    final puzzle = _puzzles[_currentIndex];
    final answers = _controllers.map((c) => c.text).toList();

    Future.delayed(const Duration(milliseconds: 350), () async {
      final attempt = checkPuzzle(puzzle, answers);
      var rewarded = false;
      var newlyUnlockedAchievements = <AchievementProgress>[];
      if (attempt.verdict == Verdict.correct) {
        rewarded = await _progress.completePuzzle(
          puzzle.id,
          language: puzzle.language,
        );
        newlyUnlockedAchievements = _progress.takeNewlyUnlockedAchievements();
      }
      if (!mounted) return;
      unawaited(
        gameAudio.playEffect(
          attempt.verdict == Verdict.correct
              ? GameSoundEffect.success
              : GameSoundEffect.error,
        ),
      );
      setState(() {
        _isExecuting = false;
      });
      _say(
        attempt.verdict == Verdict.correct
            ? 'Excellent work! You solved this one.'
            : attempt.message,
      );
      await _showResultDialog(
        attempt,
        rewarded: rewarded,
        newlyUnlockedAchievements: newlyUnlockedAchievements,
      );
    });
  }

  Future<void> _buyHint() async {
    if (_puzzles.isEmpty) return;
    final puzzle = _puzzles[_currentIndex];
    const hintCost = 10;

    final currentUnlocked = _progress.getUnlockedHints(puzzle.id);
    if (currentUnlocked >= puzzle.hints.length) {
      _say("You've unlocked all my hints for this level.");
      return;
    }

    final success = await _progress.unlockHint(
      puzzle.id,
      hintCost,
      puzzle.hints.length,
    );
    if (!mounted) return;
    final newlyUnlockedAchievements = success
        ? _progress.takeNewlyUnlockedAchievements()
        : <AchievementProgress>[];
    if (newlyUnlockedAchievements.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Achievement unlocked: ${newlyUnlockedAchievements.map((item) => item.definition.title).join(', ')}',
          ),
        ),
      );
    }
    final unlockedHintsCount = _progress.getUnlockedHints(puzzle.id);
    _say(
      success
          ? puzzle.hints[unlockedHintsCount - 1]
          : 'You need $hintCost coins for another hint. Keep solving to earn more.',
      persistent: success,
    );
    unawaited(
      gameAudio.playEffect(
        success ? GameSoundEffect.hint : GameSoundEffect.error,
      ),
    );
  }

  void _say(String message, {bool persistent = false}) {
    _mascotBubbleTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _mascotMessage = message;
      _showMascotBubble = true;
      if (persistent) _pinnedMascotHint = message;
    });
    if (persistent) return;
    _mascotBubbleTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        final pinnedHint = _pinnedMascotHint;
        if (pinnedHint == null) {
          _showMascotBubble = false;
        } else {
          _mascotMessage = pinnedHint;
        }
      });
    });
  }

  Future<void> _nextLevel() async {
    if (_currentIndex < _puzzles.length - 1) {
      final nextIndex = _currentIndex + 1;
      setState(() {
        _currentIndex = nextIndex;
        _initControllers();
      });
      _say(_mascotMessage, persistent: _pinnedMascotHint != null);
      await _progress.setCurrentPuzzleIndex(
        nextIndex,
        language: widget.language,
      );
    }
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: AppBackground(
          child: Center(
            child: CircularProgressIndicator(color: _palette.accent),
          ),
        ),
      );
    }

    if (_puzzles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('PUZZLES')),
        body: AppBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: _palette.danger,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadError ?? 'No puzzles are available right now.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _palette.text, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loadPuzzles,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('TRY AGAIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final puzzle = _puzzles[_currentIndex];
    final unlockedHintsCount = _progress.getUnlockedHints(puzzle.id);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressStrip(),
              _buildFloatingMascot(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        _pagePad,
                        4,
                        _pagePad,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStoryCard(puzzle),
                          const SizedBox(height: _gap),
                          _sectionLabel('CODE BLOCK PUZZLE'),
                          const SizedBox(height: 8),
                          _buildCodeCard(puzzle),
                          const SizedBox(height: _gap),
                          _buildActionRow(unlockedHintsCount),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingMascot() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_pagePad, 0, _pagePad, 6),
      child: SizedBox(
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: _showMascotBubble
                    ? Container(
                        key: ValueKey(_mascotMessage),
                        constraints: const BoxConstraints(maxWidth: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _palette.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _palette.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _mascotMessage,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _palette.text,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('hidden-bubble')),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _mascotFloatOffset,
                child: const Tooltip(
                  message: 'Byte, your coding companion',
                  child: CodeBotMascot(size: 48),
                ),
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _mascotFloatOffset.value),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header: back (left), coins (true center), level (right)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pagePad, vertical: 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () {
              unawaited(gameAudio.playEffect(GameSoundEffect.tap));
              Navigator.pop(context);
            },
            style: IconButton.styleFrom(
              backgroundColor: _palette.card,
              foregroundColor: _palette.muted,
              side: BorderSide(color: _palette.border),
              fixedSize: const Size(40, 40),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _palette.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _palette.border),
              boxShadow: [
                BoxShadow(
                  color: _palette.accent.withValues(alpha: 0.12),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  color: _palette.accent,
                  size: 18,
                ),
                const SizedBox(width: 5),
                ListenableBuilder(
                  listenable: _progress,
                  builder: (context, _) => Text(
                    '${_progress.coins}',
                    style: TextStyle(
                      color: _palette.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _palette.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _palette.secondary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              '${_currentIndex + 1} / ${_puzzles.length}',
              style: TextStyle(
                color: _palette.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStrip() {
    final progress = (_currentIndex + 1) / _puzzles.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_pagePad, 0, _pagePad, 8),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: _palette.accent, size: 16),
          const SizedBox(width: 6),
          Text(
            '${widget.language.label.toUpperCase()} QUEST',
            style: TextStyle(
              color: _palette.text,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: _palette.border,
                color: _palette.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'LEVEL ${_currentIndex + 1}',
            style: TextStyle(
              color: _palette.secondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: _palette.accent,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildStoryCard(Puzzle puzzle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _palette.brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.extension_rounded, color: _palette.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  puzzle.title.toUpperCase(),
                  style: TextStyle(
                    color: _palette.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _palette.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _palette.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  puzzle.language.label.toUpperCase(),
                  style: TextStyle(
                    color: _palette.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            puzzle.story,
            style: TextStyle(fontSize: 14, height: 1.5, color: _palette.muted),
          ),
          const SizedBox(height: 10),
          Text(
            "WHAT YOU'RE CODING",
            style: TextStyle(
              color: _palette.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            puzzle.task,
            style: TextStyle(
              color: _palette.text,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _palette.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _palette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'TARGET',
                  style: TextStyle(
                    color: _palette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    puzzle.expectedOutput.replaceAll('\n', ' ↵ '),
                    style: TextStyle(
                      color: _palette.success,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(Puzzle puzzle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _palette.brightness == Brightness.dark ? 0.16 : 0.04,
            ),
            blurRadius: 14,
          ),
        ],
      ),
      child: _buildCodeEditorTemplate(puzzle),
    );
  }

  Widget _buildActionRow(int unlockedHintsCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isExecuting ? null : _runCode,
              icon: _isExecuting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _palette.onAccent,
                      ),
                    )
                  : Icon(
                      Icons.play_arrow_rounded,
                      color: _palette.onAccent,
                      size: 24,
                    ),
              label: Text(
                _isExecuting ? 'RUNNING...' : 'RUN CODE',
                style: TextStyle(
                  color: _palette.onAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _palette.accent,
                foregroundColor: _palette.onAccent,
                disabledBackgroundColor: _palette.accent.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: 84,
              height: 50,
              child: Tooltip(
                message: 'Buy a hint for 10 coins',
                child: ElevatedButton(
                  onPressed: _buyHint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _palette.card,
                    foregroundColor: _palette.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    side: BorderSide(color: _palette.border),
                    elevation: 0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: _palette.accent,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '10 COINS',
                        style: TextStyle(
                          color: _palette.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _palette.secondary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unlockedHintsCount',
                  style: TextStyle(
                    color: _palette.onAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showResultDialog(
    Attempt attempt, {
    required bool rewarded,
    required List<AchievementProgress> newlyUnlockedAchievements,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _buildResultDialog(
        dialogContext,
        attempt,
        rewarded: rewarded,
        newlyUnlockedAchievements: newlyUnlockedAchievements,
      ),
    );
  }

  Widget _buildResultDialog(
    BuildContext dialogContext,
    Attempt attempt, {
    required bool rewarded,
    required List<AchievementProgress> newlyUnlockedAchievements,
  }) {
    final correct = attempt.verdict == Verdict.correct;
    final worldComplete = _currentIndex == _puzzles.length - 1;
    final color = _getVerdictColor(attempt.verdict);
    final actionLabel = !correct
        ? 'TRY AGAIN'
        : worldComplete
        ? 'RETURN TO WORLDS'
        : 'NEXT LEVEL';

    return Dialog(
      backgroundColor: _palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _palette.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CodeBotMascot(size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BYTE',
                          style: TextStyle(
                            color: _palette.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              _getVerdictIcon(attempt.verdict),
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                correct && worldComplete
                                    ? 'WORLD COMPLETE'
                                    : _getVerdictTitle(attempt.verdict),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                attempt.message,
                style: TextStyle(
                  color: _palette.text,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              if (attempt.output.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _palette.inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR OUTPUT',
                        style: TextStyle(
                          color: _palette.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        attempt.output,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: _palette.success,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (rewarded) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      color: _palette.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '+${GameProgress.puzzleReward} coins earned',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _palette.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (newlyUnlockedAchievements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _palette.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _palette.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newlyUnlockedAchievements.length == 1
                            ? 'ACHIEVEMENT UNLOCKED'
                            : 'ACHIEVEMENTS UNLOCKED',
                        style: TextStyle(
                          color: _palette.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final achievement in newlyUnlockedAchievements)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                achievement.definition.icon,
                                color: _palette.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  achievement.definition.title,
                                  style: TextStyle(
                                    color: _palette.text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    unawaited(gameAudio.playEffect(GameSoundEffect.tap));
                    Navigator.of(dialogContext).pop();
                    if (!correct) return;
                    if (worldComplete) {
                      Navigator.of(context).pop();
                    } else {
                      _nextLevel();
                    }
                  },
                  icon: Icon(
                    correct && worldComplete
                        ? Icons.public_rounded
                        : correct
                        ? Icons.arrow_forward_rounded
                        : Icons.refresh_rounded,
                    color: _palette.onAccent,
                  ),
                  label: Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _palette.onAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _palette.accent,
                    foregroundColor: _palette.onAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (correct) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    unawaited(gameAudio.playEffect(GameSoundEffect.tap));
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'STAY ON THIS LEVEL',
                    style: TextStyle(
                      color: _palette.muted,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // CODE EDITOR: one Row/Wrap PER LINE so blanks stay on their own line
  // ------------------------------------------------------------------
  Widget _buildCodeEditorTemplate(Puzzle puzzle) {
    final codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      color: _palette.text,
      height: 1.5,
    );

    final lines = puzzle.template.replaceAll('\r', '').split('\n');
    final rows = <Widget>[];
    var blankIndex = 0;

    for (final line in lines) {
      // Empty line = spacer
      if (line.trim().isEmpty) {
        rows.add(const SizedBox(height: 14));
        continue;
      }

      final parts = line.split(Puzzle.blankMarker);
      final children = <Widget>[];

      for (int j = 0; j < parts.length; j++) {
        if (parts[j].isNotEmpty) {
          children.add(Text(parts[j], style: codeStyle));
        }
        if (j < parts.length - 1) {
          final idx = blankIndex++;
          if (idx < _controllers.length) {
            children.add(_buildBlank(_controllers[idx]));
          }
        }
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _buildBlank(TextEditingController controller) {
    return Container(
      width: 96,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: _palette.accent,
        autocorrect: false,
        enableSuggestions: false,
        style: TextStyle(
          fontFamily: 'monospace',
          color: _palette.accent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          filled: true,
          fillColor: _palette.inputBg,
          hintText: '___',
          hintStyle: TextStyle(color: _palette.muted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _palette.accent.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _palette.accent, width: 2),
          ),
        ),
      ),
    );
  }

  Color _getVerdictColor(Verdict verdict) {
    switch (verdict) {
      case Verdict.correct:
        return _palette.success;
      case Verdict.error:
        return _palette.danger;
      case Verdict.wrongOutput:
        return _palette.warning;
      case Verdict.incomplete:
        return _palette.accent;
    }
  }

  IconData _getVerdictIcon(Verdict verdict) {
    switch (verdict) {
      case Verdict.correct:
        return Icons.check_circle_rounded;
      case Verdict.error:
        return Icons.error_rounded;
      case Verdict.wrongOutput:
        return Icons.warning_rounded;
      case Verdict.incomplete:
        return Icons.info_rounded;
    }
  }

  String _getVerdictTitle(Verdict verdict) {
    switch (verdict) {
      case Verdict.correct:
        return 'SUCCESS';
      case Verdict.error:
        return 'SYNTAX ERROR';
      case Verdict.wrongOutput:
        return 'WRONG OUTPUT';
      case Verdict.incomplete:
        return 'INCOMPLETE BLANKS';
    }
  }
}
