import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../providers/progress_provider.dart';

class CelebrationOverlay extends ConsumerStatefulWidget {
  const CelebrationOverlay({super.key});

  @override
  ConsumerState<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends ConsumerState<CelebrationOverlay> {
  late ConfettiController _confettiController;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(progressProvider.notifier).dismissCelebration();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stars = ref.watch(progressProvider).stars;
    return GestureDetector(
      onTap: () => ref.read(progressProvider.notifier).dismissCelebration(),
      child: Stack(
        children: [
          Container(
            color: Colors.black.withValues(alpha: 0.55),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFD700), size: 100),
                const SizedBox(height: 16),
                const Text(
                  '🎉',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                Text(
                  '$stars ⭐',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 40,
              maxBlastForce: 30,
              minBlastForce: 10,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
