import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/home_provider.dart';
import '../theme/bhasha_design_system.dart';
import 'splash_screen.dart';

class BhashaHomeScreen extends StatefulWidget {
  const BhashaHomeScreen({super.key});

  @override
  State<BhashaHomeScreen> createState() => _BhashaHomeScreenState();
}

class _BhashaHomeScreenState extends State<BhashaHomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BhashaColors.scaffold,
      body: _navIndex == 0
          ? const _HomeBody()
          : _navIndex == 1
              ? const _LettersNavPlaceholder()
              : _navIndex == 2
                  ? const _QuizNavPlaceholder()
                  : const _ProgressNavPlaceholder(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 1) {
            final home = context.read<HomeProvider>();
            if (home.activeLanguage != null) {
              Navigator.pushNamed(context, kRouteLetterGrid,
                  arguments: home.activeLanguage);
            }
            return;
          }
          if (i == 2) {
            final home = context.read<HomeProvider>();
            if (home.activeLanguage != null) {
              Navigator.pushNamed(context, kRouteQuiz,
                  arguments: home.activeLanguage);
            }
            return;
          }
          if (i == 3) {
            Navigator.pushNamed(context, kRouteProgress);
            return;
          }
          setState(() => _navIndex = i);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Letters',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_rounded),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_rounded),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}

// Placeholder for nav items that navigate to other screens
class _LettersNavPlaceholder extends StatelessWidget {
  const _LettersNavPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _QuizNavPlaceholder extends StatelessWidget {
  const _QuizNavPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ProgressNavPlaceholder extends StatelessWidget {
  const _ProgressNavPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ---------------------------------------------------------------------------
// Home body content
// ---------------------------------------------------------------------------

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderSection(),
          SizedBox(height: 16),
          _StreakBar(),
          SizedBox(height: 16),
          _QuickActionGrid(),
          _ContinueSection(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SECTION A — Header
// ---------------------------------------------------------------------------

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  static const _languageData = <Map<String, String>>[
    {'code': 'or', 'name': 'Odia', 'script': 'ଓ'},
    {'code': 'en', 'name': 'English', 'script': 'A'},
    {'code': 'hi', 'name': 'Hindi', 'script': 'ह'},
    {'code': 'ta', 'name': 'Tamil', 'script': 'அ'},
    {'code': 'te', 'name': 'Telugu', 'script': 'అ'},
    {'code': 'kn', 'name': 'Kannada', 'script': 'ಕ'},
    {'code': 'ml', 'name': 'Malayalam', 'script': 'അ'},
    {'code': 'bn', 'name': 'Bengali', 'script': 'ক'},
    {'code': 'gu', 'name': 'Gujarati', 'script': 'અ'},
    {'code': 'pa', 'name': 'Punjabi', 'script': 'ਅ'},
    {'code': 'mr', 'name': 'Marathi', 'script': 'अ'},
    {'code': 'ur', 'name': 'Urdu', 'script': 'ا'},
    {'code': 'as', 'name': 'Assamese', 'script': 'অ'},
  ];

  static final _chipColors = <String, Color>{
    'or': BhashaColors.langOdia,
    'hi': BhashaColors.langHindi,
    'ta': BhashaColors.langTamil,
    'te': BhashaColors.langTelugu,
    'kn': BhashaColors.langKannada,
    'ml': BhashaColors.langMalayalam,
    'bn': BhashaColors.langBengali,
    'gu': BhashaColors.langGujarati,
    'pa': BhashaColors.langPunjabi,
    'mr': BhashaColors.langMarathi,
    'ur': BhashaColors.langUrdu,
    'as': BhashaColors.langAssamese,
    'en': BhashaColors.langEnglish,
  };

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final activeCode = home.activeLanguage?.code ?? 'or';

    return Container(
      decoration: const BoxDecoration(
        color: BhashaColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: BhashaColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Bhasha Kids',
                    style: BhashaTextStyles.appTitle.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed('/settings'),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Text(
                  'Learn all Indian alphabets!',
                  style: BhashaTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Language chips
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _languageData.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final data = _languageData[index];
                    final code = data['code']!;
                    final isSelected = activeCode == code;
                    final chipColor =
                        _chipColors[code] ?? BhashaColors.primaryLight;

                    return GestureDetector(
                      onTap: () {
                        // Find language in DB list, or create temp one
                        final dbLangs = home.languages;
                        final match = dbLangs.cast<Language?>().firstWhere(
                              (l) => l!.code == code,
                              orElse: () => null,
                            );
                        if (match != null) {
                          home.setActiveLanguage(match);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(24),
                          border: isSelected
                              ? Border.all(
                                  color: BhashaColors.primary, width: 2)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data['script']!,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              data['name']!,
                              style: BhashaTextStyles.chip.copyWith(
                                color: BhashaColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SECTION B — Streak bar
// ---------------------------------------------------------------------------

class _StreakBar extends StatelessWidget {
  const _StreakBar();

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final days = home.streak?.current ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: BhashaColors.streakBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department,
                color: BhashaColors.primary, size: 28),
            const SizedBox(width: 10),
            Text(
              'Day streak',
              style: BhashaTextStyles.body.copyWith(
                color: BhashaColors.streakText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$days',
              style: BhashaTextStyles.streakDays,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SECTION C — Quick action grid (2x2)
// ---------------------------------------------------------------------------

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    final home = context.read<HomeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  title: 'Learn letters',
                  icon: Icons.menu_book_rounded,
                  background: BhashaColors.primaryLight,
                  titleColor: BhashaColors.primaryDark,
                  onTap: () {
                    if (home.activeLanguage != null) {
                      Navigator.pushNamed(context, kRouteLetterGrid,
                          arguments: home.activeLanguage);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  title: 'Quiz time',
                  icon: Icons.quiz_rounded,
                  background: const Color(0xFFE3F0FF),
                  titleColor: const Color(0xFF0A3D7A),
                  onTap: () {
                    if (home.activeLanguage != null) {
                      Navigator.pushNamed(context, kRouteQuiz,
                          arguments: home.activeLanguage);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  title: 'Word pictures',
                  icon: Icons.image_rounded,
                  background: const Color(0xFFE6FFE6),
                  titleColor: const Color(0xFF1A6620),
                  onTap: () {
                    if (home.activeLanguage != null) {
                      Navigator.pushNamed(context, kRouteWordExamples,
                          arguments: home.activeLanguage);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  title: 'My trophies',
                  icon: Icons.emoji_events_rounded,
                  background: const Color(0xFFFFF9E0),
                  titleColor: const Color(0xFF6B5000),
                  onTap: () {
                    Navigator.pushNamed(context, kRouteProgress);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color background;
  final Color titleColor;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.icon,
    required this.background,
    required this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(BhashaSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: titleColor, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              style: BhashaTextStyles.cardTitle.copyWith(color: titleColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SECTION D — Continue where you left off
// ---------------------------------------------------------------------------

class _ContinueSection extends StatelessWidget {
  const _ContinueSection();

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final letter = home.lastAccessedLetter;

    if (letter == null) return const SizedBox.shrink();

    final langName = home.activeLanguage?.name ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, kRouteTrace, arguments: letter);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(BhashaSpacing.radiusLg),
            border: Border.all(color: BhashaColors.tileBorderDef, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: BhashaColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    letter.unicode,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langName,
                      style: BhashaTextStyles.bodySmall,
                    ),
                    Text(
                      letter.romanized,
                      style: BhashaTextStyles.cardTitle.copyWith(
                        color: BhashaColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, kRouteTrace,
                      arguments: letter);
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
