import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/odia_letters.dart';
import '../providers/progress_provider.dart';
import '../widgets/letter_tile.dart';
import '../widgets/score_board.dart';
import '../widgets/celebration_overlay.dart';
import '../theme/app_theme.dart';

class LetterGridScreen extends ConsumerWidget {
  const LetterGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showCelebration = ref.watch(
      progressProvider.select((s) => s.showCelebration),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Column(
            children: [
              const SafeArea(child: ScoreBoard()),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      TabBar(
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        indicatorColor: AppTheme.primary,
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.circle, size: 12),
                                SizedBox(width: 6),
                                Text('ସ୍ୱର'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.square, size: 12),
                                SizedBox(width: 6),
                                Text('ବ୍ୟଞ୍ଜନ'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _LetterGrid(letters: odiaVowels),
                            _LetterGrid(letters: odiaConsonants),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showCelebration) const CelebrationOverlay(),
        ],
      ),
    );
  }
}

class _LetterGrid extends StatelessWidget {
  final List letters;

  const _LetterGrid({required this.letters});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 600 ? 6 : 4;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 0.9,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) => LetterTile(letter: letters[index]),
    );
  }
}
