import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'engine/puzzle.dart';
import 'engine/game_progress_manager.dart';

/// ---------------------------------------------------------------
/// THEME COLORS. To change the whole look, only edit the accent block.
/// ---------------------------------------------------------------
class AppColors {
  // Dark base
  static const bgTop = Color(0xFF050810);
  static const bgBottom = Color(0xFF0A1120);
  static const card = Color(0xFF0D1424);
  static const border = Color(0xFF1A2540);
  static const inputBg = Color(0xFF080D1A);
  static const text = Color(0xFFE2E8F0);
  static const muted = Color(0xFF7C8BA8);

  // Accent: Cyber Cyan
  static const accent = Color(0xFF22D3EE);
  static const secondary = Color(0xFF6366F1);
  static const success = Color(0xFF34D399);
  static const onAccent = Color(0xFF031417);

  // Status
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFF87171);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );
}

void main() {
  runApp(const CodescapeApp());
}

class CodescapeApp extends StatelessWidget {
  const CodescapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codescape',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgTop,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.secondary,
          surface: AppColors.card,
        ),
        useMaterial3: true,
      ),
      home: const LevelScreen(),
    );
  }
}

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  static const double _gap = 16; // one spacing value used everywhere
  static const double _pagePad = 20;

  List<Puzzle> _puzzles = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  final GameProgress _progress = GameProgress();

  final List<TextEditingController> _controllers = [];
  Attempt? _lastAttempt;
  bool _isExecuting = false;

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
    try {
      final jsonString = await rootBundle.loadString(
        'assets/puzzles/puzzles.json',
      );
      final data = jsonDecode(jsonString);
      final list = (data['puzzles'] as List)
          .map((j) => Puzzle.fromJson(j as Map<String, dynamic>))
          .toList();
      setState(() {
        _puzzles = list;
        _isLoading = false;
        _initControllers();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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
        final rewarded = _progress.completePuzzle(puzzle.id, reward: 25);
        if (rewarded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.star_rounded, color: AppColors.onAccent),
                  SizedBox(width: 10),
                  Text(
                    'LEVEL CLEARED! +25 Coins',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onAccent,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
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
        AppColors.secondary,
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
        AppColors.secondary,
      );
    } else {
      _snack(
        'Not enough coins! (Need $hintCost, you have ${_progress.coins})',
        AppColors.danger,
      );
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
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
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text(
            'WORLD COMPLETED!',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Amazing! You have conquered every single puzzle in Codescape!',
            style: TextStyle(color: AppColors.muted),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_puzzles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Codescape')),
        body: const Center(child: Text('No puzzles loaded.')),
      );
    }

    final puzzle = _puzzles[_currentIndex];
    final unlockedHintsCount = _progress.getUnlockedHints(puzzle.id);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.muted,
                  size: 20,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.accent, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.25),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_progress.coins}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  'LEVEL ${_currentIndex + 1}',
                  style: const TextStyle(
                    color: Color(0xFFA5B4FC),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
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
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.accent,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildStoryCard(Puzzle puzzle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.extension_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  puzzle.title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            puzzle.story,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'TARGET',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    puzzle.expectedOutput.replaceAll('\n', ' ↵ '),
                    style: const TextStyle(
                      color: AppColors.success,
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
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
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onAccent,
                      ),
                    )
                  : const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.onAccent,
                      size: 24,
                    ),
              label: Text(
                _isExecuting ? 'COMPILING...' : 'SUBMIT CODE',
                style: const TextStyle(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: ElevatedButton(
                onPressed: _buyHint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: AppColors.accent, width: 1.5),
                  elevation: 0,
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.accent,
                  size: 26,
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
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unlockedHintsCount',
                  style: const TextStyle(
                    color: Colors.white,
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
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFFA5B4FC), size: 18),
              SizedBox(width: 8),
              Text(
                'PURCHASED HINTS',
                style: TextStyle(
                  color: Color(0xFFA5B4FC),
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
                style: const TextStyle(
                  color: AppColors.text,
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
        color: color.withOpacity(0.10),
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
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          if (attempt.output.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                attempt.output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.success,
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
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.onAccent,
                ),
                label: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    color: AppColors.onAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
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
    const codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      color: AppColors.text,
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
        cursorColor: AppColors.accent,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: AppColors.accent,
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
          fillColor: AppColors.inputBg,
          hintText: '___',
          hintStyle: const TextStyle(color: AppColors.muted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.accent.withOpacity(0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
        ),
      ),
    );
  }

  Color _getVerdictColor(Verdict verdict) {
    switch (verdict) {
      case Verdict.correct:
        return AppColors.success;
      case Verdict.error:
        return AppColors.danger;
      case Verdict.wrongOutput:
        return AppColors.warning;
      case Verdict.incomplete:
        return AppColors.accent;
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
