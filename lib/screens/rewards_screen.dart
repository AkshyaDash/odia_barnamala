import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0E0),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      size: 100, color: Color(0xFFFFD700)),
                  const SizedBox(height: 24),
                  Text(
                    '${state.stars}',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF7F00),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      state.stars.clamp(0, 10),
                      (_) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.star_rounded,
                            color: Color(0xFFFFD700), size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '${state.tapCount}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5577CC),
                    ),
                  ),
                  const Icon(Icons.touch_app_rounded,
                      color: Color(0xFF88AAFF), size: 40),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(progressProvider.notifier).reset();
                      _confetti.play();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 32),
                    label: const SizedBox.shrink(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 80),
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 50,
              colors: const [
                Colors.red, Colors.blue, Colors.green,
                Colors.yellow, Colors.pink, Colors.orange,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
