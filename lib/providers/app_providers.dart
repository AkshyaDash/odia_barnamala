import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database_helper.dart';
import '../data/models/child_model.dart';
import '../data/repositories/child_repository.dart';
import '../data/repositories/letter_repository.dart';
import '../models/letter.dart';

const List<Color> _pastelColors = [
  Color(0xFFFFB3BA),
  Color(0xFFFFDFBA),
  Color(0xFFFFFFBA),
  Color(0xFFBAFFBA),
  Color(0xFFBAEEFF),
  Color(0xFFCCBAFF),
  Color(0xFFFFBAF0),
  Color(0xFFBAFFEE),
];

/// Gets or creates the default learner profile on first launch.
final currentChildProvider = FutureProvider<ChildModel>((ref) {
  return ChildRepository().getOrCreateChild('Learner');
});

typedef LetterLists = ({List<OdiaLetter> vowels, List<OdiaLetter> consonants});

/// Loads Odia letters from SQLite and splits them into vowels / consonants.
/// displayOrder 1–13 = vowels, 14+ = consonants (per OdiaLanguageSeeder).
final odiaLettersProvider = FutureProvider<LetterLists>((ref) async {
  final letters = await LetterRepository().getLettersByLanguage(1);

  final vowels = <OdiaLetter>[];
  final consonants = <OdiaLetter>[];
  int vowelIdx = 0;
  int consonantIdx = 0;

  for (final letter in letters) {
    final isVowel = letter.displayOrder <= 13;
    final colorIdx = isVowel ? vowelIdx++ : consonantIdx++;
    final uiLetter = OdiaLetter(
      character: letter.unicodeChar,
      name: letter.romanized,
      audioPath: 'assets/audio/${letter.audioFilename ?? ''}',
      tileColor: _pastelColors[colorIdx % _pastelColors.length],
      isVowel: isVowel,
      dbId: letter.id,
    );
    if (isVowel) {
      vowels.add(uiLetter);
    } else {
      consonants.add(uiLetter);
    }
  }

  return (vowels: vowels, consonants: consonants);
});

// ─── Child stats ─────────────────────────────────────────────────────────────

typedef ChildStats = ({
  int totalStars,
  int lettersPracticed,
  int currentStreak,
});

/// Lifetime stats for the current child, read directly from SQLite.
/// Invalidate this provider (ref.invalidate) after any progress save to refresh.
final childStatsProvider = FutureProvider<ChildStats>((ref) async {
  final child = await ref.watch(currentChildProvider.future);
  if (child.id == null) {
    return (totalStars: 0, lettersPracticed: 0, currentStreak: 0);
  }
  final db = DatabaseHelper.instance;

  final starsRows = await db.rawQuery(
    'SELECT COALESCE(SUM(stars_earned), 0) AS total '
    'FROM ${DatabaseHelper.tableProgress} WHERE child_id = ?',
    [child.id],
  );
  final totalStars = (starsRows.first['total'] as num).toInt();

  final practicedRows = await db.rawQuery(
    'SELECT COUNT(*) AS cnt '
    'FROM ${DatabaseHelper.tableProgress} '
    'WHERE child_id = ? AND mastery_level >= 1',
    [child.id],
  );
  final lettersPracticed = (practicedRows.first['cnt'] as num).toInt();

  return (
    totalStars: totalStars,
    lettersPracticed: lettersPracticed,
    currentStreak: child.currentStreak,
  );
});
