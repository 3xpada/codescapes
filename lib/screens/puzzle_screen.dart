import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../widgets/app_background.dart';
import '../theme/app_colors.dart';
import '../engine/game_progress_manager.dart';
import '../engine/puzzle.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  static const double _gap = 16; // one spacing value used everywhere
  static const double _pagePad = 20;

  List<Puzzle> _puzzles = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _loadError;
  final GameProgress _progress = gameProgress; // shared app-wide

  final List<TextEditingController> _controllers = [];
  Attempt? _lastAttempt;
  bool _isExecuting = false;
  AppPalette get _palette => context.appPalette;

  @override
  void initState() {
    super.initState();
    _loadPuzzles();
  }

  @override
  void dispose() {
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
      final jsonString = await rootBundle.loadString(
        'assets/puzzles/puzzles.json',
      );
      final data = jsonDecode(jsonString);
      final list = (data['puzzles'] as List)
          .map((j) => Puzzle.fromJson(j as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _puzzles = list;
        _isLoading = false;
        _initControllers();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load puzzles: $error';
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
    }
    _lastAttempt = null;
  }

  void _runCode() {
    if (_puzzles.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isExecuting = true;
    });

    final puzzle = _puzzles[_currentIndex];
    final answers = _controllers.map((c) => c.text).toList();

    Future.delayed(const Duration(milliseconds: 350), () {
      final attempt = checkPuzzle(puzzle, answers);
      if (!mounted) return;
      setState(() {
        _lastAttempt = attempt;
        _isExecuting = false;
      });

      if (attempt.verdict == Verdict.correct) {
        final rewarded = _progress.completePuzzle(puzzle.id);
        if (rewarded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.monetization_on_rounded, color: _palette.onAccent),
                  const SizedBox(width: 10),
                  Text(
                    'PUZZLE SOLVED! +${GameProgress.puzzleReward} COINS',
                    style: TextStyle(
                      color: _palette.onAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              backgroundColor: _palette.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _buyHint() {
    if (_puzzles.isEmpty) return;
    final puzzle = _puzzles[_currentIndex];
    const hintCost = 10;

    final currentUnlocked = _progress.getUnlockedHints(puzzle.id);
    if (currentUnlocked >= puzzle.hints.length) {
      _snack(
        'All hints for this level are already unlocked!',
        _palette.secondary,
      );
      return;
    }

    final success = _progress.unlockHint(
      puzzle.id,
      hintCost,
      puzzle.hints.length,
    );
    if (success) {
      setState(() {});
      _snack(
        'Hint #${currentUnlocked + 1} unlocked (-$hintCost coins)',
        _palette.secondary,
      );
    } else {
      _snack(
        'Not enough coins! (Need $hintCost, you have ${_progress.coins})',
        _palette.danger,
      );
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: _palette.text)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(milliseconds: 1400),
        ),
      );
  }

  void _nextLevel() {
    if (_currentIndex < _puzzles.length - 1) {
      setState(() {
        _currentIndex++;
        _initControllers();
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _palette.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _palette.border),
          ),
          title: Text(
            'WORLD COMPLETED!',
            style: TextStyle(
              color: _palette.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Amazing! You have conquered every single puzzle in Codescape!',
            style: TextStyle(color: _palette.muted),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _palette.accent,
                foregroundColor: _palette.onAccent,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'AWESOME',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(_pagePad, 4, _pagePad, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStoryCard(puzzle),
                      const SizedBox(height: _gap + 4),
                      _sectionLabel('CODE BLOCK PUZZLE'),
                      const SizedBox(height: 10),
                      _buildCodeCard(puzzle),
                      const SizedBox(height: _gap + 4),
                      _buildActionRow(unlockedHintsCount),
                      if (unlockedHintsCount > 0) ...[
                        const SizedBox(height: _gap),
                        _buildHintsPanel(puzzle, unlockedHintsCount),
                      ],
                      if (_lastAttempt != null) ...[
                        const SizedBox(height: _gap),
                        _buildVerdictCard(_lastAttempt!),
                      ],
                    ],
                  ),
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
            onPressed: () => Navigator.pop(context),
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
      padding: const EdgeInsets.all(18),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _palette.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _palette.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'PYTHON',
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
          const SizedBox(height: 10),
          Text(
            puzzle.story,
            style: TextStyle(fontSize: 14, height: 1.5, color: _palette.muted),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 14),
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
      padding: const EdgeInsets.all(20),
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
            height: 56,
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
              height: 56,
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

  Widget _buildHintsPanel(Puzzle puzzle, int unlockedHintsCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _palette.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _palette.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: _palette.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'PURCHASED HINTS',
                style: TextStyle(
                  color: _palette.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < unlockedHintsCount; i++)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• ${puzzle.hints[i]}',
                style: TextStyle(
                  color: _palette.text,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerdictCard(Attempt attempt) {
    final color = _getVerdictColor(attempt.verdict);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getVerdictIcon(attempt.verdict), color: color),
              const SizedBox(width: 10),
              Text(
                _getVerdictTitle(attempt.verdict),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            attempt.message,
            style: TextStyle(fontSize: 13, height: 1.4, color: _palette.muted),
          ),
          if (attempt.output.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _palette.inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                attempt.output,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: _palette.success,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          if (attempt.verdict == Verdict.correct) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _nextLevel,
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: _palette.onAccent,
                ),
                label: Text(
                  'CONTINUE',
                  style: TextStyle(
                    color: _palette.onAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
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
          ],
        ],
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
