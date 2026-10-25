import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'engine/puzzle.dart';
import 'engine/game_progress_manager.dart';

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
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.amber,
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

  Future<void> _loadPuzzles() async {
    try {
      final jsonString = await rootBundle.loadString('assets/puzzles/puzzles.json');
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
                  Icon(Icons.star_rounded, color: Colors.amber),
                  SizedBox(width: 10),
                  Text('LEVEL CLEARED! +25 Coins Added! 🪙', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  // Bulk Hint Unlocking Logic: Tap to buy hints back-to-back until out of coins or hints
  void _buyHint() {
    if (_puzzles.isEmpty) return;
    final puzzle = _puzzles[_currentIndex];
    const hintCost = 10;
    
    final currentUnlocked = _progress.getUnlockedHints(puzzle.id);
    if (currentUnlocked >= puzzle.hints.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ All hints for this level are already unlocked!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = _progress.unlockHint(puzzle.id, hintCost, puzzle.hints.length);
    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💡 Hint #${currentUnlocked + 1} Unlocked! (-$hintCost Coins)'),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Not enough coins! (Need $hintCost, you have ${_progress.coins})'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🏆 WORLD COMPLETED!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: const Text('Amazing! You have conquered every single puzzle in Codescape!', style: TextStyle(color: Colors.white70)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(context),
              child: const Text('AWESOME', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF090D16)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Game Header Bar (Coins, Back, Level counter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.amber, width: 2),
                        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${_progress.coins}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: Text(
                        'LEVEL ${_currentIndex + 1}',
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Story / Puzzle Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.extension_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 8),
                                Text(puzzle.title.toUpperCase(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(puzzle.story, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white70)),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  const Text('TARGET: ', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      puzzle.expectedOutput.replaceAll('\n', ' ↵ '),
                                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('CODE BLOCK PUZZLE:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1.2)),
                      const SizedBox(height: 10),

                      // Code Editor Tile Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                        ),
                        child: _buildCodeEditorTemplate(puzzle),
                      ),
                      const SizedBox(height: 24),

                      // Action Controls (Submit Code + Floating Circle Hint)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isExecuting ? null : _runCode,
                              icon: _isExecuting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                              label: Text(_isExecuting ? 'COMPILING...' : 'SUBMIT CODE', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Circular hint button with badge counter
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _buyHint,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF334155),
                                    shape: const CircleBorder(),
                                    padding: EdgeInsets.zero,
                                    side: const BorderSide(color: Colors.amber, width: 2),
                                  ),
                                  child: const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 26),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$unlockedHintsCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Unlocked Hints Panel
                      if (unlockedHintsCount > 0) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                                  SizedBox(width: 8),
                                  Text('PURCHASED HINTS:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              for (int i = 0; i < unlockedHintsCount; i++)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('• ${puzzle.hints[i]}', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                                ),
                            ],
                          ),
                        ),
                      ],

                      // Verdict Card Result
                      if (_lastAttempt != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _getVerdictColor(_lastAttempt!.verdict).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _getVerdictColor(_lastAttempt!.verdict), width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_getVerdictIcon(_lastAttempt!.verdict), color: _getVerdictColor(_lastAttempt!.verdict)),
                                  const SizedBox(width: 10),
                                  Text(
                                    _getVerdictTitle(_lastAttempt!.verdict),
                                    style: TextStyle(
                                      color: _getVerdictColor(_lastAttempt!.verdict),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(_lastAttempt!.message, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70)),
                              if (_lastAttempt!.output.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _lastAttempt!.output,
                                    style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12),
                                  ),
                                ),
                              ],
                              if (_lastAttempt!.verdict == Verdict.correct) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _nextLevel,
                                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                                    label: const Text('CONTINUE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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

  Widget _buildCodeEditorTemplate(Puzzle puzzle) {
    final parts = puzzle.template.split(Puzzle.blankMarker);
    final widgets = <Widget>[];

    for (int i = 0; i < parts.length; i++) {
      widgets.add(Text(
        parts[i],
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.white70, height: 1.6),
      ));

      if (i < _controllers.length) {
        widgets.add(
          Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: TextField(
              controller: _controllers[i],
              style: const TextStyle(fontFamily: 'monospace', color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: '___',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.amber.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: widgets,
    );
  }

  Color _getVerdictColor(Verdict verdict) {
    switch (verdict) {
      case Verdict.correct:
        return Colors.greenAccent;
      case Verdict.error:
        return Colors.redAccent;
      case Verdict.wrongOutput:
        return Colors.orangeAccent;
      case Verdict.incomplete:
        return Colors.amberAccent;
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