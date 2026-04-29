// Bhasha Kids design system — colors, typography, spacing, and shared widgets.
// BhashaLetterTile is named distinctly to avoid conflict with the existing
// LetterTile widget in lib/widgets/letter_tile.dart.

import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// 1. COLOR PALETTE
// -----------------------------------------------------------------------------
class BhashaColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFFF0E6);
  static const Color primaryDark = Color(0xFFCC4400);

  static const Color trace = Color(0xFF7C3AED);
  static const Color traceLight = Color(0xFFEDE9FE);
  static const Color traceDark = Color(0xFF4C1D95);
  static const Color traceBorder = Color(0xFFC4B5FD);

  static const Color quiz = Color(0xFF0F766E);
  static const Color quizLight = Color(0xFFF0FDFA);
  static const Color quizBorder = Color(0xFF99F6E4);
  static const Color quizAccent = Color(0xFF5EEAD4);

  static const Color progress = Color(0xFF0369A1);
  static const Color progressLight = Color(0xFFF0F9FF);
  static const Color progressBorder = Color(0xFFBAE6FD);

  static const Color scaffold = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F5F5);

  static const Color tileDefault = Color(0xFFFFFFFF);
  static const Color tileLearned = Color(0xFFFFF0E6);
  static const Color tileBorderDef = Color(0xFFFFD0B5);
  static const Color tileBorderLearned = Color(0xFFFF6B35);
  static const Color tileLocked = Color(0xFFF5F5F5);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);

  static const Color streakBg = Color(0xFFFFF0E6);
  static const Color streakText = Color(0xFFCC4400);

  static const Color optionCorrect = Color(0xFFF0FFF4);
  static const Color optionCorrectBorder = Color(0xFF22C55E);
  static const Color optionWrong = Color(0xFFFFF5F5);
  static const Color optionWrongBorder = Color(0xFFEF4444);

  // Language card backgrounds
  static const Color langOdia = Color(0xFFFFF0E6);
  static const Color langHindi = Color(0xFFFFF0F5);
  static const Color langTamil = Color(0xFFF0F5FF);
  static const Color langTelugu = Color(0xFFF0FFF5);
  static const Color langKannada = Color(0xFFFFF8E1);
  static const Color langBengali = Color(0xFFF5F0FF);
  static const Color langGujarati = Color(0xFFFFFAF0);
  static const Color langMalayalam = Color(0xFFF0FFFA);
  static const Color langPunjabi = Color(0xFFFFF5E6);
  static const Color langMarathi = Color(0xFFF5FFF0);
  static const Color langUrdu = Color(0xFFF0F5FF);
  static const Color langAssamese = Color(0xFFFFF8F5);
  static const Color langEnglish  = Color(0xFFE6F0FF);
}

// -----------------------------------------------------------------------------
// 2. TYPOGRAPHY
// -----------------------------------------------------------------------------
class BhashaTextStyles {
  // Nunito for Latin UI; Odia chars auto-fall-back to bundled NotoSansOriya.
  static const String fontFamily = 'Nunito';

  static const TextStyle appTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: BhashaColors.textHint,
    letterSpacing: 0.07,
  );

  // No fontFamily override — NotoSansOriya (bundled) covers Odia glyphs;
  // other scripts fall back to system Noto fonts automatically.
  static const TextStyle letterChar = TextStyle(
    fontFamily: 'NotoSansOriya',
    fontSize: 24,
    height: 1.0,
  );

  static const TextStyle letterHero = TextStyle(
    fontFamily: 'NotoSansOriya',
    fontSize: 64,
    height: 1.0,
  );

  static const TextStyle letterRoman = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: BhashaColors.textHint,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle cardSub = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    color: BhashaColors.textSecondary,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: BhashaColors.progress,
  );

  static const TextStyle streakDays = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: BhashaColors.primary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: BhashaColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: BhashaColors.textSecondary,
  );

  static const TextStyle chip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}

// -----------------------------------------------------------------------------
// 3. SPACING & RADIUS
// -----------------------------------------------------------------------------
class BhashaSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;
  static const double radiusCircle = 999.0;
}

// -----------------------------------------------------------------------------
// 4. WIDGETS
// -----------------------------------------------------------------------------

/// Rounded header used on every sub-screen.
class BhashaHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onBack;
  final Widget? trailing;

  const BhashaHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.fromLTRB(
        BhashaSpacing.lg,
        BhashaSpacing.lg,
        BhashaSpacing.lg,
        BhashaSpacing.xl,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: BhashaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BhashaTextStyles.screenTitle),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: BhashaTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Letter tile used in the grid — three visual states: learned, default, locked.
class BhashaLetterTile extends StatelessWidget {
  final String character;
  final String romanization;
  final bool isLearned;
  final bool isLocked;
  final VoidCallback? onTap;

  const BhashaLetterTile({
    super.key,
    required this.character,
    required this.romanization,
    this.isLearned = false,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isLearned
        ? BhashaColors.tileLearned
        : isLocked
            ? BhashaColors.tileLocked
            : BhashaColors.tileDefault;

    final Color border = isLearned
        ? BhashaColors.tileBorderLearned
        : isLocked
            ? const Color(0xFFDDDDDD)
            : BhashaColors.tileBorderDef;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                BorderRadius.circular(BhashaSpacing.radiusMd),
            border: Border.all(color: border, width: 2),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(character,
                        style: BhashaTextStyles.letterChar),
                    Text(romanization,
                        style: BhashaTextStyles.letterRoman),
                  ],
                ),
              ),
              if (isLearned)
                const Positioned(
                  top: 4,
                  right: 6,
                  child: Text(
                    '★',
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFFFFB800)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Star rating row (0–3 stars).
class StarRating extends StatelessWidget {
  final int stars;

  const StarRating({super.key, required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '★',
            style: TextStyle(
              fontSize: 28,
              color: i < stars
                  ? const Color(0xFFFFB800)
                  : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}

/// Section label shown above grid sections.
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsets padding;

  const SectionLabel(
    this.text, {
    super.key,
    this.padding =
        const EdgeInsets.fromLTRB(16, 16, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: BhashaTextStyles.sectionLabel,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. THEME DATA
// -----------------------------------------------------------------------------
ThemeData bhashaTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: BhashaTextStyles.fontFamily,
    scaffoldBackgroundColor: BhashaColors.scaffold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BhashaColors.primary,
      primary: BhashaColors.primary,
      surface: BhashaColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BhashaColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: BhashaTextStyles.screenTitle,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: BhashaColors.surface,
      selectedItemColor: BhashaColors.primary,
      unselectedItemColor: BhashaColors.textHint,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BhashaColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BhashaSpacing.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BhashaSpacing.lg,
          vertical: BhashaSpacing.md,
        ),
        textStyle: const TextStyle(
          fontFamily: BhashaTextStyles.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// 6. ADDITIONAL SHARED WIDGETS
// -----------------------------------------------------------------------------

/// Progress bar row used in language progress list.
class LanguageProgressRow extends StatelessWidget {
  final String languageName;
  final String script;
  final double progress;
  final Color color;

  const LanguageProgressRow({
    super.key,
    required this.languageName,
    required this.script,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: BhashaSpacing.sm),
      padding: const EdgeInsets.all(BhashaSpacing.md),
      decoration: BoxDecoration(
        color: BhashaColors.surface,
        borderRadius: BorderRadius.circular(BhashaSpacing.radiusMd),
        border: Border.all(color: BhashaColors.progressBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(script, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(languageName,
                  style: BhashaTextStyles.cardTitle
                      .copyWith(color: BhashaColors.progress)),
              const Spacer(),
              Text('${(progress * 100).round()}%',
                  style: BhashaTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: BhashaColors.progressLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat card for the progress screen.
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BhashaSpacing.md),
      decoration: BoxDecoration(
        color: BhashaColors.surface,
        borderRadius: BorderRadius.circular(BhashaSpacing.radiusMd),
        border: Border.all(color: BhashaColors.progressBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Text(value,
              style: BhashaTextStyles.statValue.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: BhashaTextStyles.bodySmall.copyWith(fontSize: 9),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Quiz option tile.
class QuizOption extends StatelessWidget {
  final String character;
  final String label;
  final bool isCorrect;
  final bool isWrong;
  final bool isSelected;
  final VoidCallback onTap;

  const QuizOption({
    super.key,
    required this.character,
    required this.label,
    this.isCorrect = false,
    this.isWrong = false,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = isCorrect
        ? BhashaColors.optionCorrect
        : isWrong
            ? BhashaColors.optionWrong
            : BhashaColors.surface;

    Color border = isCorrect
        ? BhashaColors.optionCorrectBorder
        : isWrong
            ? BhashaColors.optionWrongBorder
            : BhashaColors.quizBorder;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(BhashaSpacing.radiusMd),
          border: Border.all(color: border, width: 2.5),
        ),
        child: Column(
          children: [
            Text(character,
                style: const TextStyle(fontSize: 28, height: 1.2)),
            const SizedBox(height: 4),
            Text(label,
                style: BhashaTextStyles.bodySmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
