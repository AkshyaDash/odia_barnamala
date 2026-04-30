import 'package:flutter/material.dart';

import '../data/bhasha_database_helper.dart';
import '../models/language.dart';
import '../models/letter_new.dart';
import '../models/letter_progress.dart';
import '../screens/splash_screen.dart';
import '../theme/bhasha_design_system.dart';

class LetterGridScreen extends StatefulWidget {
  final Language language;

  const LetterGridScreen({super.key, required this.language});

  @override
  State<LetterGridScreen> createState() => _LetterGridScreenState();
}

class _LetterGridScreenState extends State<LetterGridScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Letter> _letters = [];
  Map<int, LetterProgress> _progressMap = {};
  bool _loading = true;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final letters = await _db.getLettersForLanguage(widget.language.id!);
    final allProgress = await _db.getAllProgress();

    final progressMap = <int, LetterProgress>{};
    for (final p in allProgress) {
      progressMap[p.letterId] = p;
    }

    if (mounted) {
      setState(() {
        _letters = letters;
        _progressMap = progressMap;
        _loading = false;
      });
    }
  }

  Future<void> _onTileTap(Letter letter) async {
    await Navigator.of(context).pushNamed(kRouteTrace, arguments: letter);
    // Refresh progress after returning from trace screen
    if (mounted) _loadData();
  }

  Future<void> _showResetConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BhashaSpacing.radiusLg),
        ),
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
        content: Text(
          'This will erase all progress for ${widget.language.name}.',
          style: const TextStyle(
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
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: BhashaTextStyles.fontFamily)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset',
                style: TextStyle(fontFamily: BhashaTextStyles.fontFamily)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _resetting = true);
      await _db.resetProgressForLanguage(widget.language.id!);
      if (mounted) {
        setState(() => _resetting = false);
        _loadData();
      }
    }
  }

  String _vowelTabLabel(String code) {
    const native = {
      'or': 'ସ୍ୱର', 'hi': 'स्वर', 'mr': 'स्वर', 'bn': 'স্বর',
      'gu': 'સ્વર', 'pa': 'ਸਵਰ', 'ta': 'உயிர்', 'te': 'అచ్చులు',
      'kn': 'ಸ್ವರ', 'ml': 'സ്വരം',
    };
    final n = native[code];
    return n != null ? '$n  Vowels' : 'Vowels';
  }

  String _consonantTabLabel(String code) {
    const native = {
      'or': 'ବ୍ୟଞ୍ଜନ', 'hi': 'व्यंजन', 'mr': 'व्यंजन', 'bn': 'ব্যঞ্জন',
      'gu': 'વ્યંજન', 'pa': 'ਵਿਅੰਜਨ', 'ta': 'மெய்', 'te': 'హల్లులు',
      'kn': 'ವ್ಯಂಜನ', 'ml': 'വ്യഞ്ജനം',
    };
    final n = native[code];
    return n != null ? '$n  Consonants' : 'Consonants';
  }

  @override
  Widget build(BuildContext context) {
    final learnedCount =
        _progressMap.values.where((p) => p.stars > 0).length;
    final totalCount = _letters.length;

    // Split into vowels (sort_order 1-13) and consonants (14+)
    final vowels = _letters.where((l) => l.sortOrder <= 13).toList();
    final consonants = _letters.where((l) => l.sortOrder > 13).toList();

    // Compute progressive unlock per group
    int vowelLearned = vowels
        .where((l) => (_progressMap[l.id]?.stars ?? 0) > 0)
        .length;
    int consonantLearned = consonants
        .where((l) => (_progressMap[l.id]?.stars ?? 0) > 0)
        .length;
    final vowelCeiling = vowelLearned + 8;
    final consonantCeiling = consonantLearned + 8;

    final String subtitle =
        _loading ? '' : '$learnedCount of $totalCount letters learned';

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
                  title: '${widget.language.name} Alphabet',
                  subtitle: _loading ? null : subtitle,
                  color: BhashaColors.primary,
                  onBack: () => Navigator.pop(context),
                  trailing: GestureDetector(
                    onTap: _resetting ? null : _showResetConfirm,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.restart_alt,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
              if (!_loading) _ProgressBar(learned: learnedCount, total: totalCount),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: BhashaColors.primary))
                    : DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            TabBar(
                              indicatorColor: BhashaColors.primary,
                              labelColor: BhashaColors.primary,
                              unselectedLabelColor: BhashaColors.textHint,
                              labelStyle: const TextStyle(
                                fontFamily: BhashaTextStyles.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontFamily: BhashaTextStyles.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              tabs: [
                                Tab(text: _vowelTabLabel(widget.language.code)),
                                Tab(text: _consonantTabLabel(widget.language.code)),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _LetterGrid(
                                    letters: vowels,
                                    progressMap: _progressMap,
                                    unlockCeiling: vowelCeiling,
                                    onTap: _onTileTap,
                                  ),
                                  _LetterGrid(
                                    letters: consonants,
                                    progressMap: _progressMap,
                                    unlockCeiling: consonantCeiling,
                                    onTap: _onTileTap,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          if (_resetting)
            const ColoredBox(
              color: Colors.black26,
              child: Center(
                  child: CircularProgressIndicator(
                      color: BhashaColors.primary)),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar
// ---------------------------------------------------------------------------

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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(BhashaColors.primary),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4-column letter grid
// ---------------------------------------------------------------------------

class _LetterGrid extends StatelessWidget {
  final List<Letter> letters;
  final Map<int, LetterProgress> progressMap;
  final int unlockCeiling;
  final Future<void> Function(Letter) onTap;

  const _LetterGrid({
    required this.letters,
    required this.progressMap,
    required this.unlockCeiling,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final crossCount = MediaQuery.of(context).size.width > 600 ? 5 : 3;

    return GridView.builder(
      padding: const EdgeInsets.all(BhashaSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 1.0,
        crossAxisSpacing: BhashaSpacing.sm,
        mainAxisSpacing: BhashaSpacing.sm,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final letter = letters[index];
        final progress = progressMap[letter.id];
        final isLearned = (progress?.stars ?? 0) > 0;
        // +1 because index is 0-based, ceiling is 1-based count
        final isLocked = !isLearned && (index + 1) > unlockCeiling;

        return BhashaLetterTile(
          character: letter.unicode,
          romanization: letter.romanized,
          isLearned: isLearned,
          isLocked: isLocked,
          onTap: () => onTap(letter),
        );
      },
    );
  }
}
