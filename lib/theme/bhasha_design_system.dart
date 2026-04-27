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
