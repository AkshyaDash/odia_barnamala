import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../data/bhasha_database_helper.dart';
import '../models/letter_new.dart';
import '../painters/letter_trace_painter.dart';
import '../providers/home_provider.dart';
import '../theme/bhasha_design_system.dart';

class LetterTraceScreen extends StatefulWidget {
  final Letter letter;

  const LetterTraceScreen({super.key, required this.letter});

  @override
  State<LetterTraceScreen> createState() => _LetterTraceScreenState();
}

class _LetterTraceScreenState extends State<LetterTraceScreen>
    with SingleTickerProviderStateMixin {
  final List<List<Offset>> _drawnStrokes = [];
  List<Offset> _currentStroke = [];
  double _totalDrawnLength = 0;
  double _canvasShortestSide = 300.0;

  bool _completed = false;

  late ConfettiController _confetti;
  late AnimationController _starPulse;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Color _inkColor = Colors.orangeAccent;

  static const double _targetFraction = 3.0;
  static const double _completionPercent = 0.95;

  static const _colorOptions = [
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.blueAccent,
    Colors.tealAccent,
    Colors.greenAccent,
    Colors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _starPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _playLetterAudio();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _starPulse.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Strip "assets/" prefix — audioplayers uses AssetSource which prepends it
  Future<void> _playLetterAudio() async {
    try {
      await _audioPlayer.stop();
      final path = widget.letter.audioFile.replaceFirst('assets/', '');
      await _audioPlayer.play(AssetSource(path));
    } catch (_) {}
  }

  // ─── Gesture callbacks ───────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (_completed) return;
    setState(() {
      _currentStroke = [d.localPosition];
      _drawnStrokes.add(_currentStroke);
    });
  }

  void _onPanUpdate(DragUpdateDetails d, Size canvasSize) {
    if (_completed) return;
    final newPoint = d.localPosition;
    if (_currentStroke.isNotEmpty) {
      _totalDrawnLength += (newPoint - _currentStroke.last).distance;
    }
    _canvasShortestSide = canvasSize.shortestSide;
    setState(() => _currentStroke.add(newPoint));
    if (_traceProgress >= _completionPercent) {
      _triggerCompletion();
    }
  }

  void _onPanEnd(DragEndDetails d, Size canvasSize) {
    if (_completed) return;
    _canvasShortestSide = canvasSize.shortestSide;
    if (_traceProgress >= _completionPercent) {
      _triggerCompletion();
    }
  }

  double get _traceProgress =>
      (_totalDrawnLength / (_canvasShortestSide * _targetFraction)).clamp(0.0, 1.0);

  // ─── Completion ─────────────────────────────────────────────────────────

  void _triggerCompletion() {
    if (_completed) return;
    setState(() => _completed = true);
    _confetti.play();
    _starPulse.repeat(reverse: true);
    _persistProgress();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showCompletionDialog();
    });
  }

  Future<void> _persistProgress() async {
    final id = widget.letter.id;
    if (id == null) return;
    try {
      await DatabaseHelper.instance.saveProgress(id, 1);
      await DatabaseHelper.instance.updateStreak();
      // Refresh the streak shown on the home screen
      if (mounted) {
        context.read<HomeProvider>().refreshStreak();
        context.read<HomeProvider>().refreshLastAccessed();
      }
    } catch (_) {}
  }

  void _showCompletionDialog() {
    final nav = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(
        letter: widget.letter,
        onNext: () {
          if (nav.canPop()) nav.pop(); // dismiss dialog
          if (nav.canPop()) nav.pop(); // back to grid
        },
      ),
    );
  }

  void _resetTrace() {
    setState(() {
      _drawnStrokes.clear();
      _currentStroke = [];
      _totalDrawnLength = 0;
      _completed = false;
    });
    _starPulse.stop();
    _starPulse.reset();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BhashaColors.traceLight,
      body: Stack(
        children: [
          // Tracing canvas
          _TracingArea(
            character: widget.letter.unicode,
            drawnStrokes: _drawnStrokes,
            inkColor: _inkColor,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
          ),

          // Letter name + replay (top-left)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.letter.unicode,
                        style: const TextStyle(
                          fontSize: 40,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        widget.letter.romanized,
                        style: const TextStyle(
                          fontFamily: BhashaTextStyles.fontFamily,
                          fontSize: 14,
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _playLetterAudio,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        size: 20,
                        color: BhashaColors.trace,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Close button (top-right)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
          ),

          // Reset button (bottom-left)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FloatingActionButton.small(
                  heroTag: 'trace_reset',
                  backgroundColor: Colors.white,
                  elevation: 4,
                  onPressed: _resetTrace,
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.grey),
                ),
              ),
            ),
          ),

          // Progress badge (bottom-right)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: _starPulse,
                  builder: (context, child) {
                    final scale = 1.0 + _starPulse.value * 0.15;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: BhashaColors.traceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: BhashaColors.traceBorder, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _completed
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: _completed
                              ? const Color(0xFFFFB800)
                              : BhashaColors.textHint,
                          size: 28,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _completed
                              ? 'Done!'
                              : '${(_traceProgress * 100).round()}%',
                          style: TextStyle(
                            fontFamily: BhashaTextStyles.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _completed
                                ? const Color(0xFF7D5A00)
                                : BhashaColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Color picker strip (bottom-center)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _colorOptions.map((color) {
                      final selected = color.toARGB32() == _inkColor.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => _inkColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selected ? 34 : 28,
                          height: selected ? 34 : 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.black87
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 50,
              maxBlastForce: 40,
              minBlastForce: 15,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tracing canvas
// ---------------------------------------------------------------------------

class _TracingArea extends StatefulWidget {
  final String character;
  final List<List<Offset>> drawnStrokes;
  final Color inkColor;
  final void Function(DragStartDetails) onPanStart;
  final void Function(DragUpdateDetails, Size) onPanUpdate;
  final void Function(DragEndDetails, Size) onPanEnd;

  const _TracingArea({
    required this.character,
    required this.drawnStrokes,
    required this.inkColor,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  State<_TracingArea> createState() => _TracingAreaState();
}

class _TracingAreaState extends State<_TracingArea> {
  Size _canvasSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: widget.onPanStart,
      onPanUpdate: (d) => widget.onPanUpdate(d, _canvasSize),
      onPanEnd: (d) => widget.onPanEnd(d, _canvasSize),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          return CustomPaint(
            size: _canvasSize,
            painter: LetterTracePainter(
              character: widget.character,
              drawnStrokes: widget.drawnStrokes,
              inkColor: widget.inkColor,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Completion dialog
// ---------------------------------------------------------------------------

class _CompletionDialog extends StatefulWidget {
  final Letter letter;
  final VoidCallback onNext;

  const _CompletionDialog({required this.letter, required this.onNext});

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  Timer? _autoNav;

  @override
  void initState() {
    super.initState();
    _autoNav = Timer(const Duration(seconds: 3), widget.onNext);
  }

  @override
  void dispose() {
    _autoNav?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 160,
              child: Lottie.asset(
                'assets/lottie/celebration.json',
                repeat: true,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Great Job!',
              style: TextStyle(
                fontFamily: BhashaTextStyles.fontFamily,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: BhashaColors.trace,
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Color(0xFFFFD700), size: 22),
                Text(
                  '1 Star',
                  style: TextStyle(
                    fontFamily: BhashaTextStyles.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.star_rounded,
                    color: Color(0xFFFFD700), size: 28),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.letter.unicode,
              style: const TextStyle(fontSize: 52, height: 1.0),
            ),
            Text(
              widget.letter.romanized,
              style: const TextStyle(
                fontFamily: BhashaTextStyles.fontFamily,
                fontSize: 16,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BhashaColors.trace,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: widget.onNext,
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontFamily: BhashaTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
