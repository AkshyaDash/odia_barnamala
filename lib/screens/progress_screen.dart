import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bhasha_database_helper.dart';
import '../providers/bhasha_progress_provider.dart';
import '../theme/bhasha_design_system.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<_BadgeData> _badges = [];
  List<_RecentItem> _recentItems = [];
  bool _loaded = false;
  String _childName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadProgress();
      _loadBadgesAndRecent();
    });
  }

  Future<void> _loadBadgesAndRecent() async {
    final db = DatabaseHelper.instance;
    final prefs = await SharedPreferences.getInstance();

    final allProgress = await db.getAllProgress();
    final streak = await db.getStreak();
    final quizResults = await db.getRecentQuizResults(100);
    final wordVisits = prefs.getInt('word_visits') ?? 0;

    final totalLearned = allProgress.where((p) => p.stars > 0).length;
    final hasAnyQuiz80 = quizResults.any((q) => q.score >= 80);

    // Count letters learned per day (simplified check)
    // For badge 5: check if 5 letters share the same date prefix
    bool fiveInOneDay = false;
    final dateCounts = <String, int>{};
    for (final p in allProgress) {
      if (p.learnedAt != null && p.stars > 0) {
        final date = p.learnedAt!.substring(0, 10);
        dateCounts[date] = (dateCounts[date] ?? 0) + 1;
        if (dateCounts[date]! >= 5) fiveInOneDay = true;
      }
    }

    // Count languages started
    final langCountRows = await db.getAllLanguages();
    int langsStarted = 0;
    for (final lang in langCountRows) {
      if (lang.id != null) {
        final count = await db.getLearnedCount(lang.id!);
        if (count > 0) langsStarted++;
      }
    }

    // Check all vowels learned (sort_order 1-16 in any language)
    bool allVowels = false;
    for (final lang in langCountRows) {
      if (lang.id == null) continue;
      final vowels = await db.getVowelsForLanguage(lang.id!);
      if (vowels.isEmpty) continue;
      bool allLearned = true;
      for (final v in vowels) {
        final prog = await db.getProgress(v.id!);
        if (prog == null || prog.stars == 0) {
          allLearned = false;
          break;
        }
      }
      if (allLearned && vowels.isNotEmpty) {
        allVowels = true;
        break;
      }
    }

    _badges = [
      _BadgeData(
        label: 'First letter',
        emoji: '\u{1F31F}',
        earned: totalLearned > 0,
        color: BhashaColors.primary,
      ),
      _BadgeData(
        label: 'Quiz hero',
        emoji: '\u{1F389}',
        earned: hasAnyQuiz80,
        color: BhashaColors.quiz,
      ),
      _BadgeData(
        label: '7-day streak',
        emoji: '\u{1F525}',
        earned: streak.longest >= 7,
        color: const Color(0xFF854F0B),
      ),
      _BadgeData(
        label: 'All vowels',
        emoji: '\u{2728}',
        earned: allVowels,
        color: BhashaColors.trace,
      ),
      _BadgeData(
        label: 'Speedy learner',
        emoji: '\u{26A1}',
        earned: fiveInOneDay,
        color: const Color(0xFF0369A1),
      ),
      _BadgeData(
        label: 'Word explorer',
        emoji: '\u{1F4D6}',
        earned: wordVisits >= 10,
        color: const Color(0xFF059669),
      ),
      _BadgeData(
        label: 'Tri-lingual',
        emoji: '\u{1F30D}',
        earned: langsStarted >= 3,
        color: BhashaColors.primary,
      ),
      _BadgeData(
        label: 'Champion',
        emoji: '\u{1F3C6}',
        earned: totalLearned >= 100,
        color: const Color(0xFF854F0B),
      ),
    ];

    // Recent activity — use raw query to join letter + language names
    final rawDb = await db.database;
    final recentRows = await rawDb.rawQuery('''
      SELECT p.*, l.unicode, l.romanized, lang.name as lang_name
      FROM progress p
      JOIN letters l ON p.letter_id = l.id
      JOIN languages lang ON l.lang_id = lang.id
      WHERE p.learned_at IS NOT NULL
      ORDER BY p.learned_at DESC
      LIMIT 5
    ''');
    _recentItems = recentRows.map((row) {
      final learnedAt = row['learned_at'] as String?;
      String timeAgo = '';
      if (learnedAt != null) {
        final dt = DateTime.tryParse(learnedAt);
        if (dt != null) {
          final diff = DateTime.now().difference(dt);
          if (diff.inMinutes < 60) {
            timeAgo = '${diff.inMinutes}m ago';
          } else if (diff.inHours < 24) {
            timeAgo = '${diff.inHours}h ago';
          } else {
            timeAgo = '${diff.inDays}d ago';
          }
        }
      }
      return _RecentItem(
        character: row['unicode'] as String,
        langName: row['lang_name'] as String,
        stars: row['stars'] as int,
        timeAgo: timeAgo,
      );
    }).toList();

    final childName = prefs.getString('child_name') ?? '';
    if (mounted) {
      setState(() {
        _loaded = true;
        _childName = childName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    // Calculate level
    final total = progress.totalLearned;
    String levelTitle;
    int levelNum;
    if (total <= 20) {
      levelNum = 1;
      levelTitle = 'Beginner';
    } else if (total <= 50) {
      levelNum = 2;
      levelTitle = 'Explorer';
    } else if (total <= 100) {
      levelNum = 3;
      levelTitle = 'Scholar';
    } else if (total <= 200) {
      levelNum = 4;
      levelTitle = 'Master';
    } else {
      levelNum = 5;
      levelTitle = 'Champion';
    }

    return Scaffold(
      backgroundColor: BhashaColors.scaffold,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BhashaHeader(
              title: 'My progress',
              subtitle: 'Keep going, superstar!',
              color: BhashaColors.progress,
              onBack: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Profile section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: BhashaColors.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: BhashaColors.primary, width: 3),
                          ),
                          child: const Icon(Icons.child_care_rounded,
                              size: 36, color: BhashaColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _childName.isEmpty ? 'Learner' : _childName,
                          style: BhashaTextStyles.cardTitle.copyWith(
                            fontSize: 16,
                            color: BhashaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: BhashaColors.progressLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: BhashaColors.progressBorder),
                          ),
                          child: Text(
                            'Level $levelNum — $levelTitle',
                            style: BhashaTextStyles.chip.copyWith(
                              color: BhashaColors.progress,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Stat cards
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          value: '${progress.totalLearned}',
                          label: 'Letters\nlearned',
                          color: BhashaColors.progress,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          value: '${progress.streak?.current ?? 0}',
                          label: 'Day\nstreak',
                          color: BhashaColors.progress,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          value: '${progress.languagesExplored}',
                          label: 'Languages\nexplored',
                          color: BhashaColors.progress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 3. Language progress
                  const SectionLabel('Language progress'),
                  ...progress.languages
                      .where((lang) =>
                          lang.id != null &&
                          (progress.learnedPerLanguage[lang.id] ?? 0) > 0)
                      .map((lang) {
                    final learned =
                        progress.learnedPerLanguage[lang.id!] ?? 0;
                    final total = lang.totalLetters;
                    final pct = total > 0 ? learned / total : 0.0;

                    Color barColor;
                    switch (lang.code) {
                      case 'or':
                        barColor = BhashaColors.primary;
                        break;
                      case 'hi':
                        barColor = const Color(0xFFAA2255);
                        break;
                      case 'ta':
                        barColor = const Color(0xFF2244AA);
                        break;
                      case 'te':
                        barColor = const Color(0xFF116633);
                        break;
                      case 'kn':
                        barColor = const Color(0xFF885500);
                        break;
                      default:
                        barColor = BhashaColors.progress;
                    }

                    return LanguageProgressRow(
                      languageName: lang.name,
                      script: lang.script,
                      progress: pct,
                      color: barColor,
                    );
                  }),

                  // 4. Badges
                  const SectionLabel('Badges'),
                  if (_loaded)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _badges.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final badge = _badges[index];
                          return _BadgeItem(badge: badge);
                        },
                      ),
                    ),

                  // 5. Recent activity
                  const SectionLabel('Recent activity'),
                  if (_recentItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No activity yet. Start learning!',
                        style: BhashaTextStyles.bodySmall.copyWith(
                          color: BhashaColors.textHint,
                        ),
                      ),
                    ),
                  ..._recentItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Text(
                            item.character,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            item.langName,
                            style: BhashaTextStyles.body
                                .copyWith(fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(
                                item.stars,
                                (_) => const Text('\u2605',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFFFB800))),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.timeAgo,
                                style: BhashaTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge data & widget
// ---------------------------------------------------------------------------

class _BadgeData {
  final String label;
  final String emoji;
  final bool earned;
  final Color color;

  const _BadgeData({
    required this.label,
    required this.emoji,
    required this.earned,
    required this.color,
  });
}

class _BadgeItem extends StatelessWidget {
  final _BadgeData badge;

  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: badge.earned
                    ? badge.color.withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: badge.earned ? badge.color : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(badge.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            if (badge.earned)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB800),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('\u2713',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          child: Text(
            badge.label,
            style: BhashaTextStyles.bodySmall.copyWith(fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );

    if (!badge.earned) {
      content = Opacity(
        opacity: 0.3,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.grey,
            BlendMode.saturation,
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}

// ---------------------------------------------------------------------------
// Recent activity item
// ---------------------------------------------------------------------------

class _RecentItem {
  final String character;
  final String langName;
  final int stars;
  final String timeAgo;

  const _RecentItem({
    required this.character,
    required this.langName,
    required this.stars,
    required this.timeAgo,
  });
}
