// lib/data/database/odia_seeder.dart
//
// Seeds the `languages` and `letters` tables with the complete Odia barnamala:
//   13 vowels  (swaras)
//   36 consonants (byanjanas)
//
// Idempotent — calling seed() more than once is safe; it returns immediately
// if Odia is already present.
//
// Stroke paths are pulled from letter_trace_paths.dart (the same Catmull-Rom
// spline data the tracing screen already uses) and converted to StrokePoint
// format for storage.

import '../letter_trace_paths.dart' show getTracePaths;
import 'database_helper.dart';
import '../models/language_model.dart';
import '../models/letter_model.dart';

// ---------------------------------------------------------------------------
// Internal definition record — not exported
// ---------------------------------------------------------------------------
class _LetterDef {
  final String unicode;
  final String romanized;
  final String audioFilename; // bare filename, no 'assets/audio/' prefix
  final String? exampleWord;
  final String? exampleWordMeaning;

  const _LetterDef({
    required this.unicode,
    required this.romanized,
    required this.audioFilename,
    this.exampleWord,
    this.exampleWordMeaning,
  });
}

// ---------------------------------------------------------------------------
// Seeder
// ---------------------------------------------------------------------------
class OdiaLanguageSeeder {
  OdiaLanguageSeeder._();

  /// Seeds Odia data into [db]. Safe to call at every app start.
  static Future<void> seed(DatabaseHelper db) async {
    // Idempotency guard — exit early if language row already exists
    final existing = await db.queryOne(
      DatabaseHelper.tableLanguages,
      where: 'name = ?',
      whereArgs: ['Odia'],
    );
    if (existing != null) return;

    // --- 1. Insert language row -------------------------------------------
    final language = LanguageModel(
      name: 'Odia',
      nativeName: 'ଓଡ଼ିଆ',
      scriptFamily: 'odia',
      totalLetters: _letterDefs.length,
      isUnlocked: true,  // Odia is the default unlocked language
      displayOrder: 1,
    );
    final languageId = await db.insert(
      DatabaseHelper.tableLanguages,
      language.toMap(),
    );

    // --- 2. Insert all letters in display order ---------------------------
    for (int i = 0; i < _letterDefs.length; i++) {
      final def = _letterDefs[i];

      // Convert List<List<Offset>> → List<List<StrokePoint>>
      final strokes = getTracePaths(def.unicode)
          .map((stroke) =>
              stroke.map((o) => StrokePoint(dx: o.dx, dy: o.dy)).toList())
          .toList();

      final letter = LetterModel(
        languageId: languageId,
        unicodeChar: def.unicode,
        romanized: def.romanized,
        strokeOrder: strokes,
        audioFilename: def.audioFilename,
        exampleWord: def.exampleWord,
        exampleWordMeaning: def.exampleWordMeaning,
        displayOrder: i + 1,
      );

      await db.insert(DatabaseHelper.tableLetters, letter.toMap());
    }
  }

  // ---------------------------------------------------------------------------
  // Letter definitions — 13 vowels then 36 consonants
  // ---------------------------------------------------------------------------
  static const List<_LetterDef> _letterDefs = [
    // ── Vowels (Swaras) ────────────────────────────────────────────────────
    _LetterDef(
      unicode: 'ଅ', romanized: 'A',
      audioFilename: 'vowel_a.mp3',
      exampleWord: 'ଅଙ୍କ', exampleWordMeaning: 'Number',
    ),
    _LetterDef(
      unicode: 'ଆ', romanized: 'Aa',
      audioFilename: 'vowel_aa.mp3',
      exampleWord: 'ଆମ', exampleWordMeaning: 'Mango',
    ),
    _LetterDef(
      unicode: 'ଇ', romanized: 'I',
      audioFilename: 'vowel_i.mp3',
      exampleWord: 'ଇଟ', exampleWordMeaning: 'Brick',
    ),
    _LetterDef(
      unicode: 'ଈ', romanized: 'Ii',
      audioFilename: 'vowel_ii.mp3',
      exampleWord: 'ଈଶ', exampleWordMeaning: 'God',
    ),
    _LetterDef(
      unicode: 'ଉ', romanized: 'U',
      audioFilename: 'vowel_u.mp3',
      exampleWord: 'ଉଟ', exampleWordMeaning: 'Camel',
    ),
    _LetterDef(
      unicode: 'ଊ', romanized: 'Uu',
      audioFilename: 'vowel_uu.mp3',
      exampleWord: 'ଊଷ', exampleWordMeaning: 'Dawn',
    ),
    _LetterDef(
      unicode: 'ଋ', romanized: 'Ru',
      audioFilename: 'vowel_ru.mp3',
      exampleWord: 'ଋଷି', exampleWordMeaning: 'Sage',
    ),
    _LetterDef(
      unicode: 'ଏ', romanized: 'E',
      audioFilename: 'vowel_e.mp3',
      exampleWord: 'ଏକ', exampleWordMeaning: 'One',
    ),
    _LetterDef(
      unicode: 'ଐ', romanized: 'Ai',
      audioFilename: 'vowel_ai.mp3',
      exampleWord: 'ଐରାବତ', exampleWordMeaning: 'Divine elephant',
    ),
    _LetterDef(
      unicode: 'ଓ', romanized: 'O',
      audioFilename: 'vowel_o.mp3',
      exampleWord: 'ଓଡ଼ିଆ', exampleWordMeaning: 'Odia language',
    ),
    _LetterDef(
      unicode: 'ଔ', romanized: 'Au',
      audioFilename: 'vowel_au.mp3',
      exampleWord: 'ଔଷଧ', exampleWordMeaning: 'Medicine',
    ),
    _LetterDef(
      unicode: 'ଅଂ', romanized: 'Am',
      audioFilename: 'vowel_am.mp3',
      exampleWord: 'ଅଂଶ', exampleWordMeaning: 'Part / Share',
    ),
    _LetterDef(
      unicode: 'ଅଃ', romanized: 'Ah',
      audioFilename: 'vowel_ah.mp3',
      exampleWord: 'ଅଃ', exampleWordMeaning: 'Visarga mark',
    ),

    // ── Consonants (Byanjanas) ─────────────────────────────────────────────
    _LetterDef(
      unicode: 'କ', romanized: 'Ka',
      audioFilename: 'consonant_ka.mp3',
      exampleWord: 'କଳ', exampleWordMeaning: 'Art',
    ),
    _LetterDef(
      unicode: 'ଖ', romanized: 'Kha',
      audioFilename: 'consonant_kha.mp3',
      exampleWord: 'ଖାଦ୍ୟ', exampleWordMeaning: 'Food',
    ),
    _LetterDef(
      unicode: 'ଗ', romanized: 'Ga',
      audioFilename: 'consonant_ga.mp3',
      exampleWord: 'ଗଧ', exampleWordMeaning: 'Donkey',
    ),
    _LetterDef(
      unicode: 'ଘ', romanized: 'Gha',
      audioFilename: 'consonant_gha.mp3',
      exampleWord: 'ଘଣ୍ଟା', exampleWordMeaning: 'Bell',
    ),
    _LetterDef(
      unicode: 'ଙ', romanized: 'Nga',
      audioFilename: 'consonant_nga.mp3',
      exampleWord: 'ଅଙ୍ଗ', exampleWordMeaning: 'Body part',
    ),
    _LetterDef(
      unicode: 'ଚ', romanized: 'Cha',
      audioFilename: 'consonant_cha.mp3',
      exampleWord: 'ଚନ୍ଦ୍ର', exampleWordMeaning: 'Moon',
    ),
    _LetterDef(
      unicode: 'ଛ', romanized: 'Chha',
      audioFilename: 'consonant_chha.mp3',
      exampleWord: 'ଛାତ', exampleWordMeaning: 'Umbrella',
    ),
    _LetterDef(
      unicode: 'ଜ', romanized: 'Ja',
      audioFilename: 'consonant_ja.mp3',
      exampleWord: 'ଜଳ', exampleWordMeaning: 'Water',
    ),
    _LetterDef(
      unicode: 'ଝ', romanized: 'Jha',
      audioFilename: 'consonant_jha.mp3',
      exampleWord: 'ଝୁଲ', exampleWordMeaning: 'Swing',
    ),
    _LetterDef(
      unicode: 'ଞ', romanized: 'Nya',
      audioFilename: 'consonant_nya.mp3',
      exampleWord: 'ଞ', exampleWordMeaning: 'Palatal nasal',
    ),
    _LetterDef(
      unicode: 'ଟ', romanized: 'Ta',
      audioFilename: 'consonant_ta.mp3',
      exampleWord: 'ଟୋପ', exampleWordMeaning: 'Hat',
    ),
    _LetterDef(
      unicode: 'ଠ', romanized: 'Tha',
      audioFilename: 'consonant_tha.mp3',
      exampleWord: 'ଠଣ୍ଡ', exampleWordMeaning: 'Cold',
    ),
    _LetterDef(
      unicode: 'ଡ', romanized: 'Da',
      audioFilename: 'consonant_da.mp3',
      exampleWord: 'ଡ଼ାକ', exampleWordMeaning: 'Call',
    ),
    _LetterDef(
      unicode: 'ଢ', romanized: 'Dha',
      audioFilename: 'consonant_dha.mp3',
      exampleWord: 'ଢୋଲ', exampleWordMeaning: 'Drum',
    ),
    _LetterDef(
      unicode: 'ଣ', romanized: 'Na',
      audioFilename: 'consonant_na.mp3',
      exampleWord: 'ଗଣ', exampleWordMeaning: 'Group',
    ),
    _LetterDef(
      unicode: 'ତ', romanized: 'Ta',
      audioFilename: 'consonant_ta2.mp3',
      exampleWord: 'ତୋଟ', exampleWordMeaning: 'Parrot',
    ),
    _LetterDef(
      unicode: 'ଥ', romanized: 'Tha',
      audioFilename: 'consonant_tha2.mp3',
      exampleWord: 'ଥଳ', exampleWordMeaning: 'Plate',
    ),
    _LetterDef(
      unicode: 'ଦ', romanized: 'Da',
      audioFilename: 'consonant_da2.mp3',
      exampleWord: 'ଦୁଧ', exampleWordMeaning: 'Milk',
    ),
    _LetterDef(
      unicode: 'ଧ', romanized: 'Dha',
      audioFilename: 'consonant_dha2.mp3',
      exampleWord: 'ଧନ', exampleWordMeaning: 'Wealth',
    ),
    _LetterDef(
      unicode: 'ନ', romanized: 'Na',
      audioFilename: 'consonant_na2.mp3',
      exampleWord: 'ନଦୀ', exampleWordMeaning: 'River',
    ),
    _LetterDef(
      unicode: 'ପ', romanized: 'Pa',
      audioFilename: 'consonant_pa.mp3',
      exampleWord: 'ପଦ୍ମ', exampleWordMeaning: 'Lotus',
    ),
    _LetterDef(
      unicode: 'ଫ', romanized: 'Pha',
      audioFilename: 'consonant_pha.mp3',
      exampleWord: 'ଫୁଲ', exampleWordMeaning: 'Flower',
    ),
    _LetterDef(
      unicode: 'ବ', romanized: 'Ba',
      audioFilename: 'consonant_ba.mp3',
      exampleWord: 'ବାଘ', exampleWordMeaning: 'Tiger',
    ),
    _LetterDef(
      unicode: 'ଭ', romanized: 'Bha',
      audioFilename: 'consonant_bha.mp3',
      exampleWord: 'ଭଲ୍ଲୁକ', exampleWordMeaning: 'Bear',
    ),
    _LetterDef(
      unicode: 'ମ', romanized: 'Ma',
      audioFilename: 'consonant_ma.mp3',
      exampleWord: 'ମଛ', exampleWordMeaning: 'Fish',
    ),
    _LetterDef(
      unicode: 'ଯ', romanized: 'Ya',
      audioFilename: 'consonant_ya.mp3',
      exampleWord: 'ଯାତ୍ରା', exampleWordMeaning: 'Journey',
    ),
    _LetterDef(
      unicode: 'ର', romanized: 'Ra',
      audioFilename: 'consonant_ra.mp3',
      exampleWord: 'ରଙ୍ଗ', exampleWordMeaning: 'Colour',
    ),
    _LetterDef(
      unicode: 'ଲ', romanized: 'La',
      audioFilename: 'consonant_la.mp3',
      exampleWord: 'ଲଡ଼ୁ', exampleWordMeaning: 'Sweet ball',
    ),
    _LetterDef(
      unicode: 'ଵ', romanized: 'Va',
      audioFilename: 'consonant_va.mp3',
      exampleWord: 'ଵଂଶ', exampleWordMeaning: 'Bamboo',
    ),
    _LetterDef(
      unicode: 'ଶ', romanized: 'Sha',
      audioFilename: 'consonant_sha.mp3',
      exampleWord: 'ଶଙ୍ଖ', exampleWordMeaning: 'Conch shell',
    ),
    _LetterDef(
      unicode: 'ଷ', romanized: 'Ssa',
      audioFilename: 'consonant_ssa.mp3',
      exampleWord: 'ଷଡ଼', exampleWordMeaning: 'Six',
    ),
    _LetterDef(
      unicode: 'ସ', romanized: 'Sa',
      audioFilename: 'consonant_sa.mp3',
      exampleWord: 'ସୂର୍ଯ୍ୟ', exampleWordMeaning: 'Sun',
    ),
    _LetterDef(
      unicode: 'ହ', romanized: 'Ha',
      audioFilename: 'consonant_ha.mp3',
      exampleWord: 'ହାତ', exampleWordMeaning: 'Hand',
    ),
    _LetterDef(
      unicode: 'ଳ', romanized: 'Lla',
      audioFilename: 'consonant_lla.mp3',
      exampleWord: 'ଭୁଳ', exampleWordMeaning: 'Mistake',
    ),
    _LetterDef(
      unicode: 'କ୍ଷ', romanized: 'Ksha',
      audioFilename: 'consonant_ksha.mp3',
      exampleWord: 'କ୍ଷୀର', exampleWordMeaning: 'Milk / Nectar',
    ),
    _LetterDef(
      unicode: 'ଜ୍ଞ', romanized: 'Gya',
      audioFilename: 'consonant_gya.mp3',
      exampleWord: 'ଜ୍ଞାନ', exampleWordMeaning: 'Knowledge',
    ),
  ];
}
