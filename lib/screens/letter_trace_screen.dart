import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../models/letter.dart';
import '../painters/letter_trace_painter.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';

class LetterTraceScreen extends ConsumerStatefulWidget {
  final OdiaLetter letter;

  const LetterTraceScreen({super.key, required this.letter});

  @override
  ConsumerState<LetterTraceScreen> createState() => _LetterTraceScreenState();
}

class _LetterTraceScreenState extends ConsumerState<LetterTraceScreen>
    with SingleTickerProviderStateMixin {
  // User-drawn strokes in canvas coordinates.
  final List<List<Offset>> _drawnStrokes = [];
  List<Offset> _currentStroke = [];

  // Running total of pixels drawn across all strokes.
  double _totalDrawnLength = 0;

  bool _completed = false;
  int _score = 0;

  late ConfettiController _confetti;
  late AnimationController _starPulse;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // The user must draw this fraction of the canvas's short side before the
  // trace is considered complete.  Tune up/down for difficulty.
  static const double _completionFraction = 1.2;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _starPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _playAudio();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _starPulse.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      await _audioPlayer.play(
        AssetSource(widget.letter.audioPath.replaceFirst('assets/', '')),
      );
    } catch (_) {
      // Audio file may not exist yet — silent fail.
    }
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
    setState(() => _currentStroke.add(newPoint));
  }

  void _onPanEnd(DragEndDetails d, Size canvasSize) {
    if (_completed) return;
    final threshold = canvasSize.shortestSide * _completionFraction;
    if (_totalDrawnLength >= threshold) {
      _triggerCompletion();
    }
  }

  // ─── Completion logic ────────────────────────────────────────────────────

  void _triggerCompletion() {
    if (_completed) return;
    setState(() {
      _completed = true;
      _score += 5;
    });
    _confetti.play();
    _starPulse.repeat(reverse: true);
    ref.read(progressProvider.notifier).onLetterTraced(widget.letter.character);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showCompletionDialog();
    });
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  void _showCompletionDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(
        letter: widget.letter,
        onNext: () {
          Navigator.of(context).pop(); // dialog
          Navigator.of(context).pop(); // trace screen
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Main tracing area ──────────────────────────────────────────
          _TracingArea(
            character: widget.letter.character,
            drawnStrokes: _drawnStrokes,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
          ),

          // ── Letter name label (top-left) ──────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.letter.character,
                    style: AppTheme.odiaLetterStyle(size: 40),
                  ),
                  Text(
                    widget.letter.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Close button (top-right) ──────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _CloseButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),

          // ── Reset button (bottom-left) ────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FloatingActionButton.small(
                  heroTag: 'reset',
                  backgroundColor: Colors.white,
                  elevation: 4,
                  onPressed: _resetTrace,
                  child: const Icon(Icons.refresh_rounded, color: Colors.grey),
                ),
              ),
            ),
          ),

          // ── Score card (bottom-right) ─────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _ScoreCard(score: _score, pulse: _starPulse),
              ),
            ),
          ),

          // ── Confetti ─────────────────────────────────────────────────
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

// ─── Tracing area widget ────────────────────────────────────────────────────

class _TracingArea extends StatefulWidget {
  final String character;
  final List<List<Offset>> drawnStrokes;
  final void Function(DragStartDetails) onPanStart;
  final void Function(DragUpdateDetails, Size) onPanUpdate;
  final void Function(DragEndDetails, Size) onPanEnd;

  const _TracingArea({
    required this.character,
    required this.drawnStrokes,
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
            ),
          );
        },
      ),
    );
  }
}

// ─── Reusable widgets ────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
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
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final AnimationController pulse;

  const _ScoreCard({required this.score, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final scale = 1.0 + pulse.value * 0.15;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Score',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7D5A00),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 26),
          ],
        ),
      ),
    );
  }
}

// ─── Completion dialog ────────────────────────────────────────────────────────

class _CompletionDialog extends StatefulWidget {
  final OdiaLetter letter;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
            Text(
              'Great Job!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Color(0xFFFFD700), size: 22),
                Text(
                  '5 Stars',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 28),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.letter.character,
              style: AppTheme.odiaLetterStyle(size: 52),
            ),
            Text(
              widget.letter.name,
              style: const TextStyle(
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
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                onPressed: widget.onNext,
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
