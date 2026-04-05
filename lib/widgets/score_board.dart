import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/progress_provider.dart';

class ScoreBoard extends ConsumerWidget {
  const ScoreBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFEEDD),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 32),
          const SizedBox(width: 8),
          Text(
            '${state.stars}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF7F00),
            ),
          ),
          const SizedBox(width: 24),
          const Icon(Icons.touch_app_rounded, color: Color(0xFF88AAFF), size: 28),
          const SizedBox(width: 8),
          Text(
            '${state.tapCount}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5577CC),
            ),
          ),
        ],
      ),
    );
  }
}
