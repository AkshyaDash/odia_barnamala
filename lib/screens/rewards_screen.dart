import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

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
    final statsAsync = ref.watch(childStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0E0),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: statsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => const Text('Could not load stats'),
                data: (stats) => _StatsBody(stats: stats),
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

class _StatsBody extends StatelessWidget {
  final ChildStats stats;

  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events_rounded,
            size: 100, color: Color(0xFFFFD700)),
        const SizedBox(height: 24),

        // ── Total stars ──────────────────────────────────────────────────
        Text(
          '${stats.totalStars}',
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF7F00),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            stats.totalStars.clamp(0, 10),
            (_) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.star_rounded,
                  color: Color(0xFFFFD700), size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Total Stars',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 32),

        // ── Letters practiced + streak ───────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
              icon: Icons.auto_stories_rounded,
              color: const Color(0xFF5577CC),
              value: '${stats.lettersPracticed}',
              label: 'Letters',
            ),
            const SizedBox(width: 24),
            _StatChip(
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFFF5722),
              value: '${stats.currentStreak}',
              label: 'Day streak',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
