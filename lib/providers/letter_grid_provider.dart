import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/progress_model.dart';
import '../data/repositories/letter_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../models/letter.dart';
import 'app_providers.dart';

const List<Color> _tileColors = [
  Color(0xFFFFB3BA),
  Color(0xFFFFDFBA),
  Color(0xFFFFFFBA),
  Color(0xFFBAFFBA),
  Color(0xFFBAEEFF),
  Color(0xFFCCBAFF),
  Color(0xFFFFBAF0),
  Color(0xFFBAFFEE),
];

/// Combined letter + progress data for a single tile in the grid.
class LetterGridItem {
  final String character;
  final String romanization;

  /// True when the letter has been practiced at least once (mastery >= 1).
  final bool isLearned;

  /// True when the letter is not yet accessible (too far ahead in sequence).
  final bool isLocked;

  final int starsEarned;

  /// Passed through to LetterTraceScreen on tap.
  final OdiaLetter odiaLetter;

  const LetterGridItem({
    required this.character,
    required this.romanization,
    required this.isLearned,
    required this.isLocked,
    required this.starsEarned,
    required this.odiaLetter,
  });
}

typedef LetterGridData = ({
  List<LetterGridItem> vowels,
  List<LetterGridItem> consonants,
  int learnedCount,
  int totalCount,
});

/// Loads all Odia letters from SQLite and joins them with the current child's
/// progress rows to compute [isLearned] / [isLocked] states for each tile.
///
/// A rolling unlock window keeps 8 unlearned letters accessible at all times,
/// matching the mockup's progressive-reveal pattern.
///
/// Invalidate this provider after any tracing session completes so the grid
/// reflects the latest star counts.
final letterGridProvider = FutureProvider<LetterGridData>((ref) async {
  final child = await ref.watch(currentChildProvider.future);

  final letters = await LetterRepository().getLettersByLanguage(1);

  final Map<int, ProgressModel> progressMap = {};
  if (child.id != null) {
    final progressList = await ProgressRepository()
        .getProgressForChildAndLanguage(child.id!, 1);
    for (final p in progressList) {
      progressMap[p.letterId] = p;
    }
  }

  // Compute learned counts per group so the unlock window is independent
  // for vowels and consonants — otherwise all consonants start locked when
  // the global ceiling hasn't reached displayOrder 14 yet.
  int vowelLearnedCount = 0;
  int consonantLearnedCount = 0;
  for (final letter in letters) {
    final progress = letter.id != null ? progressMap[letter.id] : null;
    if ((progress?.masteryLevel ?? MasteryLevel.locked) !=
        MasteryLevel.locked) {
      if (letter.displayOrder <= 13) {
        vowelLearnedCount++;
      } else {
        consonantLearnedCount++;
      }
    }
  }

  // Total for the progress bar
  final learnedCount = vowelLearnedCount + consonantLearnedCount;

  // Each group keeps 8 unlearned letters accessible at all times.
  final vowelUnlockCeiling = vowelLearnedCount + 8;
  final consonantUnlockCeiling = consonantLearnedCount + 8;

  final vowels = <LetterGridItem>[];
  final consonants = <LetterGridItem>[];
  int vowelIdx = 0;
  int consonantIdx = 0;

  for (final letter in letters) {
    final isVowel = letter.displayOrder <= 13;
    // Position within the group (1-based) used for the unlock ceiling check.
    final posInGroup = isVowel ? vowelIdx + 1 : consonantIdx + 1;
    final colorIdx = isVowel ? vowelIdx++ : consonantIdx++;
    final unlockCeiling =
        isVowel ? vowelUnlockCeiling : consonantUnlockCeiling;

    final progress =
        letter.id != null ? progressMap[letter.id] : null;
    final isLearned =
        (progress?.masteryLevel ?? MasteryLevel.locked) !=
            MasteryLevel.locked;
    final isLocked = !isLearned && posInGroup > unlockCeiling;

    final odiaLetter = OdiaLetter(
      character: letter.unicodeChar,
      name: letter.romanized,
      audioPath: 'assets/audio/${letter.audioFilename ?? ''}',
      tileColor: _tileColors[colorIdx % _tileColors.length],
      isVowel: isVowel,
      dbId: letter.id,
    );

    final item = LetterGridItem(
      character: letter.unicodeChar,
      romanization: letter.romanized,
      isLearned: isLearned,
      isLocked: isLocked,
      starsEarned: progress?.starsEarned ?? 0,
      odiaLetter: odiaLetter,
    );

    if (isVowel) {
      vowels.add(item);
    } else {
      consonants.add(item);
    }
  }

  return (
    vowels: vowels,
    consonants: consonants,
    learnedCount: learnedCount,
    totalCount: letters.length,
  );
});
