import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/language.dart';
import '../models/letter_new.dart';
import '../models/letter_progress.dart';
import '../models/streak.dart';
import '../models/quiz_result.dart';
import '../models/word_example.dart';

class DatabaseHelper {
  static const _databaseName = 'bhasha_kids.db';
  static const _databaseVersion = 1;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE languages (
        id            INTEGER PRIMARY KEY,
        code          TEXT NOT NULL,
        name          TEXT NOT NULL,
        script        TEXT NOT NULL,
        total_letters INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE letters (
        id          INTEGER PRIMARY KEY,
        lang_id     INTEGER NOT NULL REFERENCES languages(id),
        unicode     TEXT NOT NULL,
        romanized   TEXT NOT NULL,
        audio_file  TEXT NOT NULL,
        sort_order  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE progress (
        id          INTEGER PRIMARY KEY,
        letter_id   INTEGER NOT NULL REFERENCES letters(id),
        stars       INTEGER NOT NULL DEFAULT 0,
        learned_at  TEXT,
        trace_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE streak (
        id        INTEGER PRIMARY KEY,
        last_date TEXT NOT NULL,
        current   INTEGER NOT NULL DEFAULT 0,
        longest   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_results (
        id        INTEGER PRIMARY KEY,
        lang_id   INTEGER NOT NULL,
        score     INTEGER NOT NULL,
        total     INTEGER NOT NULL,
        played_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE word_examples (
        id          INTEGER PRIMARY KEY,
        letter_id   INTEGER NOT NULL REFERENCES letters(id),
        word_script TEXT NOT NULL,
        word_roman  TEXT NOT NULL,
        word_english TEXT NOT NULL,
        image_path  TEXT,
        audio_path  TEXT
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // Languages
  // ---------------------------------------------------------------------------

  Future<List<Language>> getAllLanguages() async {
    final db = await database;
    final rows = await db.query('languages', orderBy: 'id');
    return rows.map(Language.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Letters
  // ---------------------------------------------------------------------------

  Future<List<Letter>> getLettersForLanguage(int langId) async {
    final db = await database;
    final rows = await db.query(
      'letters',
      where: 'lang_id = ?',
      whereArgs: [langId],
      orderBy: 'sort_order',
    );
    return rows.map(Letter.fromMap).toList();
  }

  Future<List<Letter>> getVowelsForLanguage(int langId) async {
    final db = await database;
    final rows = await db.query(
      'letters',
      where: 'lang_id = ? AND sort_order <= 16',
      whereArgs: [langId],
      orderBy: 'sort_order',
    );
    return rows.map(Letter.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  Future<LetterProgress?> getProgress(int letterId) async {
    final db = await database;
    final rows = await db.query(
      'progress',
      where: 'letter_id = ?',
      whereArgs: [letterId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LetterProgress.fromMap(rows.first);
  }

  Future<void> saveProgress(int letterId, int stars) async {
    final db = await database;
    final existing = await getProgress(letterId);
    final now = DateTime.now().toIso8601String();

    if (existing == null) {
      await db.insert('progress', {
        'letter_id': letterId,
        'stars': stars,
        'learned_at': now,
        'trace_count': 1,
      });
    } else {
      final newStars = stars > existing.stars ? stars : existing.stars;
      await db.update(
        'progress',
        {
          'stars': newStars,
          'learned_at': now,
          'trace_count': existing.traceCount + 1,
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }

  Future<List<LetterProgress>> getAllProgress() async {
    final db = await database;
    final rows = await db.query('progress', orderBy: 'learned_at DESC');
    return rows.map(LetterProgress.fromMap).toList();
  }

  Future<int> getLearnedCount(int langId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as cnt FROM progress p
      JOIN letters l ON p.letter_id = l.id
      WHERE l.lang_id = ? AND p.stars > 0
    ''', [langId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Letter?> getLastAccessedLetter() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT l.* FROM letters l
      JOIN progress p ON l.id = p.letter_id
      WHERE p.learned_at IS NOT NULL
      ORDER BY p.learned_at DESC
      LIMIT 1
    ''');
    if (rows.isEmpty) return null;
    return Letter.fromMap(rows.first);
  }

  // ---------------------------------------------------------------------------
  // Streak
  // ---------------------------------------------------------------------------

  Future<Streak> getStreak() async {
    final db = await database;
    final rows = await db.query('streak', limit: 1);
    if (rows.isEmpty) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await db.insert('streak', {
        'last_date': today,
        'current': 0,
        'longest': 0,
      });
      return Streak(lastDate: today, current: 0, longest: 0);
    }
    return Streak.fromMap(rows.first);
  }

  Future<void> updateStreak() async {
    final db = await database;
    final streak = await getStreak();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    if (streak.lastDate == today) return; // already counted today

    int newCurrent;
    if (streak.lastDate == yesterday) {
      newCurrent = streak.current + 1;
    } else {
      newCurrent = 1;
    }

    final newLongest =
        newCurrent > streak.longest ? newCurrent : streak.longest;

    await db.update(
      'streak',
      {
        'last_date': today,
        'current': newCurrent,
        'longest': newLongest,
      },
      where: 'id = ?',
      whereArgs: [streak.id ?? 1],
    );
  }

  // ---------------------------------------------------------------------------
  // Quiz Results
  // ---------------------------------------------------------------------------

  Future<void> saveQuizResult(int langId, int score, int total) async {
    final db = await database;
    await db.insert('quiz_results', {
      'lang_id': langId,
      'score': score,
      'total': total,
      'played_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<QuizResult>> getRecentQuizResults(int limit) async {
    final db = await database;
    final rows = await db.query(
      'quiz_results',
      orderBy: 'played_at DESC',
      limit: limit,
    );
    return rows.map(QuizResult.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Word Examples
  // ---------------------------------------------------------------------------

  Future<List<WordExample>> getWordExamples(int letterId) async {
    final db = await database;
    final rows = await db.query(
      'word_examples',
      where: 'letter_id = ?',
      whereArgs: [letterId],
    );
    return rows.map(WordExample.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Seeding
  // ---------------------------------------------------------------------------

  Future<void> seedDatabase() async {
    final db = await database;

    // Idempotency guard
    final existing = await db.query('languages', limit: 1);
    if (existing.isNotEmpty) return;

    // Seed Odia language
    final odiaId = await db.insert('languages', {
      'code': 'or',
      'name': 'Odia',
      'script': 'ଓ',
      'total_letters': 49,
    });

    // Seed Odia letters (13 vowels + 36 consonants)
    const odiaLetters = _odiaLetterDefs;
    for (int i = 0; i < odiaLetters.length; i++) {
      final def = odiaLetters[i];
      await db.insert('letters', {
        'lang_id': odiaId,
        'unicode': def['unicode'],
        'romanized': def['romanized'],
        'audio_file': 'assets/audio/${def['audio']}',
        'sort_order': i + 1,
      });
    }

    // Seed word examples for Odia vowels
    await _seedWordExamples(db);

    // Seed initial streak row
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.insert('streak', {
      'last_date': today,
      'current': 0,
      'longest': 0,
    });
  }

  Future<void> _seedWordExamples(Database db) async {
    // Get letter IDs for Odia vowels
    final letters = await db.query('letters', orderBy: 'sort_order');

    final wordData = <String, List<Map<String, String>>>{
      'ଅ': [
        {'script': 'ଅଙ୍କ', 'roman': 'anka', 'english': 'Number'},
        {'script': 'ଅଜ', 'roman': 'aja', 'english': 'Goat'},
      ],
      'ଆ': [
        {'script': 'ଆମ', 'roman': 'aama', 'english': 'Mango'},
        {'script': 'ଆଖି', 'roman': 'aakhi', 'english': 'Eye'},
      ],
      'ଇ': [
        {'script': 'ଇଟ', 'roman': 'ita', 'english': 'Brick'},
        {'script': 'ଇଲିଶ', 'roman': 'ilish', 'english': 'Hilsa fish'},
      ],
      'ଈ': [
        {'script': 'ଈଶ', 'roman': 'isha', 'english': 'God'},
        {'script': 'ଈଶ୍ୱର', 'roman': 'ishwar', 'english': 'Lord'},
      ],
      'ଉ': [
        {'script': 'ଉଟ', 'roman': 'uta', 'english': 'Camel'},
        {'script': 'ଉଲୁ', 'roman': 'ulu', 'english': 'Owl'},
      ],
      'ଊ': [
        {'script': 'ଊଷା', 'roman': 'usha', 'english': 'Dawn'},
        {'script': 'ଊର୍ମି', 'roman': 'urmi', 'english': 'Wave'},
      ],
      'ଋ': [
        {'script': 'ଋଷି', 'roman': 'rushi', 'english': 'Sage'},
        {'script': 'ଋତୁ', 'roman': 'rutu', 'english': 'Season'},
      ],
      'ଏ': [
        {'script': 'ଏକ', 'roman': 'eka', 'english': 'One'},
        {'script': 'ଏକତା', 'roman': 'ekata', 'english': 'Unity'},
      ],
      'ଐ': [
        {'script': 'ଐରାବତ', 'roman': 'airavata', 'english': 'Divine elephant'},
      ],
      'ଓ': [
        {'script': 'ଓଡ଼ିଆ', 'roman': 'odia', 'english': 'Odia language'},
        {'script': 'ଓଷ୍ଠ', 'roman': 'oshtha', 'english': 'Lip'},
      ],
      'ଔ': [
        {'script': 'ଔଷଧ', 'roman': 'aushadha', 'english': 'Medicine'},
      ],
      'ଅଂ': [
        {'script': 'ଅଂଶ', 'roman': 'ansha', 'english': 'Part'},
      ],
      'ଅଃ': [
        {'script': 'ଅଃ', 'roman': 'ah', 'english': 'Visarga mark'},
      ],
    };

    for (final letter in letters) {
      final unicode = letter['unicode'] as String;
      final words = wordData[unicode];
      if (words == null) continue;

      for (final word in words) {
        await db.insert('word_examples', {
          'letter_id': letter['id'],
          'word_script': word['script'],
          'word_roman': word['roman'],
          'word_english': word['english'],
          'image_path': null,
          'audio_path': null,
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Reset helpers (for settings screen)
  // ---------------------------------------------------------------------------

  Future<void> resetProgressForLanguage(int langId) async {
    final db = await database;
    await db.rawDelete('''
      DELETE FROM progress WHERE letter_id IN
      (SELECT id FROM letters WHERE lang_id = ?)
    ''', [langId]);
  }

  Future<void> resetAllProgress() async {
    final db = await database;
    await db.delete('progress');
    await db.delete('quiz_results');
    await db.update('streak', {'current': 0});
  }

  // ---------------------------------------------------------------------------
  // Odia letter definitions
  // ---------------------------------------------------------------------------

  static const List<Map<String, String>> _odiaLetterDefs = [
    // Vowels
    {'unicode': 'ଅ', 'romanized': 'A', 'audio': 'vowel_a.mp3'},
    {'unicode': 'ଆ', 'romanized': 'Aa', 'audio': 'vowel_aa.mp3'},
    {'unicode': 'ଇ', 'romanized': 'I', 'audio': 'vowel_i.mp3'},
    {'unicode': 'ଈ', 'romanized': 'Ii', 'audio': 'vowel_ii.mp3'},
    {'unicode': 'ଉ', 'romanized': 'U', 'audio': 'vowel_u.mp3'},
    {'unicode': 'ଊ', 'romanized': 'Uu', 'audio': 'vowel_uu.mp3'},
    {'unicode': 'ଋ', 'romanized': 'Ru', 'audio': 'vowel_ru.mp3'},
    {'unicode': 'ଏ', 'romanized': 'E', 'audio': 'vowel_e.mp3'},
    {'unicode': 'ଐ', 'romanized': 'Ai', 'audio': 'vowel_ai.mp3'},
    {'unicode': 'ଓ', 'romanized': 'O', 'audio': 'vowel_o.mp3'},
    {'unicode': 'ଔ', 'romanized': 'Au', 'audio': 'vowel_au.mp3'},
    {'unicode': 'ଅଂ', 'romanized': 'Am', 'audio': 'vowel_am.mp3'},
    {'unicode': 'ଅଃ', 'romanized': 'Ah', 'audio': 'vowel_ah.mp3'},
    // Consonants
    {'unicode': 'କ', 'romanized': 'Ka', 'audio': 'consonant_ka.mp3'},
    {'unicode': 'ଖ', 'romanized': 'Kha', 'audio': 'consonant_kha.mp3'},
    {'unicode': 'ଗ', 'romanized': 'Ga', 'audio': 'consonant_ga.mp3'},
    {'unicode': 'ଘ', 'romanized': 'Gha', 'audio': 'consonant_gha.mp3'},
    {'unicode': 'ଙ', 'romanized': 'Nga', 'audio': 'consonant_nga.mp3'},
    {'unicode': 'ଚ', 'romanized': 'Cha', 'audio': 'consonant_cha.mp3'},
    {'unicode': 'ଛ', 'romanized': 'Chha', 'audio': 'consonant_chha.mp3'},
    {'unicode': 'ଜ', 'romanized': 'Ja', 'audio': 'consonant_ja.mp3'},
    {'unicode': 'ଝ', 'romanized': 'Jha', 'audio': 'consonant_jha.mp3'},
    {'unicode': 'ଞ', 'romanized': 'Nya', 'audio': 'consonant_nya.mp3'},
    {'unicode': 'ଟ', 'romanized': 'Ta', 'audio': 'consonant_ta.mp3'},
    {'unicode': 'ଠ', 'romanized': 'Tha', 'audio': 'consonant_tha.mp3'},
    {'unicode': 'ଡ', 'romanized': 'Da', 'audio': 'consonant_da.mp3'},
    {'unicode': 'ଢ', 'romanized': 'Dha', 'audio': 'consonant_dha.mp3'},
    {'unicode': 'ଣ', 'romanized': 'Na', 'audio': 'consonant_na.mp3'},
    {'unicode': 'ତ', 'romanized': 'Ta', 'audio': 'consonant_ta2.mp3'},
    {'unicode': 'ଥ', 'romanized': 'Tha', 'audio': 'consonant_tha2.mp3'},
    {'unicode': 'ଦ', 'romanized': 'Da', 'audio': 'consonant_da2.mp3'},
    {'unicode': 'ଧ', 'romanized': 'Dha', 'audio': 'consonant_dha2.mp3'},
    {'unicode': 'ନ', 'romanized': 'Na', 'audio': 'consonant_na2.mp3'},
    {'unicode': 'ପ', 'romanized': 'Pa', 'audio': 'consonant_pa.mp3'},
    {'unicode': 'ଫ', 'romanized': 'Pha', 'audio': 'consonant_pha.mp3'},
    {'unicode': 'ବ', 'romanized': 'Ba', 'audio': 'consonant_ba.mp3'},
    {'unicode': 'ଭ', 'romanized': 'Bha', 'audio': 'consonant_bha.mp3'},
    {'unicode': 'ମ', 'romanized': 'Ma', 'audio': 'consonant_ma.mp3'},
    {'unicode': 'ଯ', 'romanized': 'Ya', 'audio': 'consonant_ya.mp3'},
    {'unicode': 'ର', 'romanized': 'Ra', 'audio': 'consonant_ra.mp3'},
    {'unicode': 'ଲ', 'romanized': 'La', 'audio': 'consonant_la.mp3'},
    {'unicode': 'ଵ', 'romanized': 'Va', 'audio': 'consonant_va.mp3'},
    {'unicode': 'ଶ', 'romanized': 'Sha', 'audio': 'consonant_sha.mp3'},
    {'unicode': 'ଷ', 'romanized': 'Ssa', 'audio': 'consonant_ssa.mp3'},
    {'unicode': 'ସ', 'romanized': 'Sa', 'audio': 'consonant_sa.mp3'},
    {'unicode': 'ହ', 'romanized': 'Ha', 'audio': 'consonant_ha.mp3'},
    {'unicode': 'ଳ', 'romanized': 'Lla', 'audio': 'consonant_lla.mp3'},
    {'unicode': 'କ୍ଷ', 'romanized': 'Ksha', 'audio': 'consonant_ksha.mp3'},
    {'unicode': 'ଜ୍ଞ', 'romanized': 'Gya', 'audio': 'consonant_gya.mp3'},
  ];
}
