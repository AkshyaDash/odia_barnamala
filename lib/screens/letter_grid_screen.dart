import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database_helper.dart';
import '../data/repositories/child_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../providers/app_providers.dart';
import '../providers/letter_grid_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/bhasha_design_system.dart';
import '../widgets/celebration_overlay.dart';
import 'letter_trace_screen.dart';

class LetterGridScreen extends ConsumerStatefulWidget {
  /// Called when the back button in the header is pressed. When null, falls
  /// back to [Navigator.maybePop] — useful when the screen is pushed as a
  /// standalone route rather than embedded inside [HomeScreen]'s IndexedStack.
  final VoidCallback? onBack;

  const LetterGridScreen({super.key, this.onBack});

  @override
  ConsumerState<LetterGridScreen> createState() => _LetterGridScreenState();
}

class _LetterGridScreenState extends ConsumerState<LetterGridScreen> {
  bool _resetting = false;

  Future<void> _onTileTap(LetterGridItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LetterTraceScreen(letter: item.odiaLetter),
      ),
    );
    if (mounted) {
      ref.invalidate(letterGridProvider);
    }
  }

  Future<void> _showResetConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _ResetConfirmDialog(),
    );
    if (confirmed == true && mounted) {
      await _performReset();
    }
  }

  Future<void> _performReset() async {
    setState(() => _resetting = true);
    try {
      final child = ref.read(currentChildProvider).valueOrNull;
      if (child?.id == null) return;
      final childId = child!.id!;

      await ProgressRepository().deleteAllProgressForChild(childId);

      await DatabaseHelper.instance.delete(
        DatabaseHelper.tableStreaks,
        where: 'child_id = ?',
        whereArgs: [childId],
      );

      await ChildRepository().updateChild(
        child.copyWith(
          totalStars: 0,
          coins: 0,
          currentStreak: 0,
          longestStreak: 0,
        ),
      );

      ref.invalidate(letterGridProvider);
      ref.invalidate(childStatsProvider);
      ref.invalidate(currentChildProvider);
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCelebration =
        ref.watch(progressProvider.select((s) => s.showCelebration));
    final gridAsync = ref.watch(letterGridProvider);

    final subtitle = gridAsync.maybeWhen(
      data: (d) => '${d.learnedCount} of ${d.totalCount} letters learned',
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: BhashaColors.scaffold,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: BhashaHeader(
                  title: 'Odia Alphabet',
                  subtitle: subtitle,
                  color: BhashaColors.primary,
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  trailing: _ResetButton(
                    onTap: _resetting ? null : _showResetConfirmation,
                  ),
                ),
              ),
              gridAsync.maybeWhen(
                data: (data) => _ProgressBar(
                  learned: data.learnedCount,
                  total: data.totalCount,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              Expanded(
                child: gridAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: BhashaColors.primary,
                    ),
                  ),
                  error: (_, __) => const Center(
                    child: Text(
                      'Could not load letters',
                      style: BhashaTextStyles.body,
                    ),
                  ),
                  data: (data) => _LetterTabs(
                    data: data,
                    onTileTap: _onTileTap,
                  ),
                ),
              ),
            ],
          ),
          if (_resetting)
            const ColoredBox(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(color: BhashaColors.primary),
              ),
            ),
          if (showCelebration) const CelebrationOverlay(),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Reset button (trailing widget inside BhashaHeader)
// -----------------------------------------------------------------------------

class _ResetButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ResetButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.restart_alt, color: Colors.white, size: 18),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Confirmation dialog
// -----------------------------------------------------------------------------

class _ResetConfirmDialog extends StatelessWidget {
  const _ResetConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BhashaSpacing.radiusLg),
      ),
      backgroundColor: BhashaColors.surface,
      icon: const Icon(Icons.restart_alt,
          color: BhashaColors.primary, size: 36),
      title: const Text(
        'Start Fresh?',
        style: TextStyle(
          fontFamily: BhashaTextStyles.fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: BhashaColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      content: const Text(
        'This will erase all your stars, streaks, and progress.\nAre you sure?',
        style: TextStyle(
          fontFamily: BhashaTextStyles.fontFamily,
          fontSize: 14,
          color: BhashaColors.textSecondary,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: BhashaColors.textSecondary,
            padding: const EdgeInsets.symmetric(
                horizontal: BhashaSpacing.xl, vertical: BhashaSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(BhashaSpacing.radiusCircle),
              side: const BorderSide(color: BhashaColors.tileBorderDef),
            ),
          ),
          child: const Text('Cancel',
              style: TextStyle(
                  fontFamily: BhashaTextStyles.fontFamily,
                  fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: BhashaSpacing.xl, vertical: BhashaSpacing.sm),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(BhashaSpacing.radiusCircle),
            ),
          ),
          child: const Text('Yes, reset',
              style: TextStyle(
                  fontFamily: BhashaTextStyles.fontFamily,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Progress bar
// -----------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  final int learned;
  final int total;

  const _ProgressBar({required this.learned, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? learned / total : 0.0;
    return Container(
      color: BhashaColors.scaffold,
      padding: const EdgeInsets.fromLTRB(
        BhashaSpacing.lg,
        BhashaSpacing.md,
        BhashaSpacing.lg,
        BhashaSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROGRESS', style: BhashaTextStyles.sectionLabel),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFEEDDCC),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  BhashaColors.primary),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Vowels / Consonants tab layout
// -----------------------------------------------------------------------------

class _LetterTabs extends StatelessWidget {
  final LetterGridData data;
  final void Function(LetterGridItem) onTileTap;

  const _LetterTabs({
    required this.data,
    required this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: BhashaColors.primary,
            labelColor: BhashaColors.primary,
            unselectedLabelColor: BhashaColors.textHint,
            labelStyle: TextStyle(
              fontFamily: BhashaTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: BhashaTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: 'ସ୍ୱର  Vowels'),
              Tab(text: 'ବ୍ୟଞ୍ଜନ  Consonants'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _LetterGrid(items: data.vowels, onTap: onTileTap),
                _LetterGrid(items: data.consonants, onTap: onTileTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4-column letter grid
// -----------------------------------------------------------------------------

class _LetterGrid extends StatelessWidget {
  final List<LetterGridItem> items;
  final void Function(LetterGridItem) onTap;

  const _LetterGrid({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final crossCount = MediaQuery.of(context).size.width > 600 ? 6 : 4;

    return GridView.builder(
      padding: const EdgeInsets.all(BhashaSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 0.9,
        crossAxisSpacing: BhashaSpacing.sm,
        mainAxisSpacing: BhashaSpacing.sm,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return BhashaLetterTile(
          character: item.character,
          romanization: item.romanization,
          isLearned: item.isLearned,
          isLocked: item.isLocked,
          onTap: () => onTap(item),
        );
      },
    );
  }
}
