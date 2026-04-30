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
  static const _databaseVersion = 2;

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
      onUpgrade: _onUpgrade,
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addMissingOdiaWords(db);
    }
  }

  Future<void> _addMissingOdiaWords(Database db) async {
    final letters = await db.rawQuery('''
      SELECT l.* FROM letters l
      JOIN languages lang ON l.lang_id = lang.id
      WHERE lang.code = 'or'
      ORDER BY l.sort_order
    ''');
    for (final letter in letters) {
      final id = letter['id'] as int;
      final unicode = letter['unicode'] as String;
      final existing = await db.query('word_examples',
          where: 'letter_id = ?', whereArgs: [id], limit: 1);
      if (existing.isNotEmpty) continue;
      final words = _odiaWordData[unicode];
      if (words == null) continue;
      for (final word in words) {
        await db.insert('word_examples', {
          'letter_id': id,
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

    // Per-language idempotency: seed each language only if absent.
    final odiaExists = await db.query('languages',
        where: 'code = ?', whereArgs: ['or'], limit: 1);
    if (odiaExists.isEmpty) {
      await _seedOdia(db);
    }

    final englishExists = await db.query('languages',
        where: 'code = ?', whereArgs: ['en'], limit: 1);
    if (englishExists.isEmpty) {
      await _seedEnglish(db);
    }

    final hindiExists = await db.query('languages',
        where: 'code = ?', whereArgs: ['hi'], limit: 1);
    if (hindiExists.isEmpty) {
      await _seedHindi(db);
    }

    final streakExists = await db.query('streak', limit: 1);
    if (streakExists.isEmpty) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await db.insert('streak', {
        'last_date': today,
        'current': 0,
        'longest': 0,
      });
    }
  }

  Future<void> _seedOdia(Database db) async {
    final odiaId = await db.insert('languages', {
      'code': 'or',
      'name': 'Odia',
      'script': 'ଓ',
      'total_letters': 49,
    });

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

    await _seedWordExamples(db);
  }

  Future<void> _seedEnglish(Database db) async {
    final langId = await db.insert('languages', {
      'code': 'en',
      'name': 'English',
      'script': 'A',
      'total_letters': 26,
    });

    const letters = _englishLetterDefs;
    for (int i = 0; i < letters.length; i++) {
      final def = letters[i];
      await db.insert('letters', {
        'lang_id': langId,
        'unicode': def['unicode'],
        'romanized': def['romanized'],
        'audio_file': 'assets/audio/${def['audio']}',
        'sort_order': i + 1,
      });
    }

    await _seedEnglishWordExamples(db);
  }

  Future<void> _seedEnglishWordExamples(Database db) async {
    final letters = await db.query('letters',
        where: "lang_id = (SELECT id FROM languages WHERE code = 'en')",
        orderBy: 'sort_order');

    const wordData = <String, List<Map<String, String>>>{
      'A': [
        {'script': 'Apple',     'roman': 'Apple',     'english': 'A red fruit'},
        {'script': 'Ant',       'roman': 'Ant',       'english': 'A small insect'},
      ],
      'E': [
        {'script': 'Elephant',  'roman': 'Elephant',  'english': 'A large animal'},
        {'script': 'Egg',       'roman': 'Egg',       'english': 'Laid by a bird'},
      ],
      'I': [
        {'script': 'Igloo',     'roman': 'Igloo',     'english': 'An ice house'},
        {'script': 'Ink',       'roman': 'Ink',       'english': 'Used for writing'},
      ],
      'O': [
        {'script': 'Orange',    'roman': 'Orange',    'english': 'A citrus fruit'},
        {'script': 'Owl',       'roman': 'Owl',       'english': 'A night bird'},
      ],
      'U': [
        {'script': 'Umbrella',  'roman': 'Umbrella',  'english': 'Keeps off rain'},
        {'script': 'Uncle',     'roman': 'Uncle',     'english': 'A family member'},
      ],
      'B': [
        {'script': 'Ball',      'roman': 'Ball',      'english': 'A round toy'},
        {'script': 'Banana',    'roman': 'Banana',    'english': 'A yellow fruit'},
      ],
      'C': [
        {'script': 'Cat',       'roman': 'Cat',       'english': 'A pet animal'},
        {'script': 'Cow',       'roman': 'Cow',       'english': 'Gives milk'},
      ],
      'D': [
        {'script': 'Dog',       'roman': 'Dog',       'english': 'A loyal pet'},
        {'script': 'Duck',      'roman': 'Duck',      'english': 'A water bird'},
      ],
      'F': [
        {'script': 'Fish',      'roman': 'Fish',      'english': 'Lives in water'},
        {'script': 'Frog',      'roman': 'Frog',      'english': 'Jumps and croaks'},
      ],
      'G': [
        {'script': 'Goat',      'roman': 'Goat',      'english': 'A farm animal'},
        {'script': 'Grapes',    'roman': 'Grapes',    'english': 'A purple fruit'},
      ],
      'H': [
        {'script': 'Hat',       'roman': 'Hat',       'english': 'Worn on head'},
        {'script': 'Horse',     'roman': 'Horse',     'english': 'A fast animal'},
      ],
      'J': [
        {'script': 'Jug',       'roman': 'Jug',       'english': 'Holds water'},
        {'script': 'Jar',       'roman': 'Jar',       'english': 'A glass container'},
      ],
      'K': [
        {'script': 'Kite',      'roman': 'Kite',      'english': 'Flies in the sky'},
        {'script': 'King',      'roman': 'King',      'english': 'Rules a kingdom'},
      ],
      'L': [
        {'script': 'Lion',      'roman': 'Lion',      'english': 'King of jungle'},
        {'script': 'Leaf',      'roman': 'Leaf',      'english': 'Part of a plant'},
      ],
      'M': [
        {'script': 'Mango',     'roman': 'Mango',     'english': 'A sweet fruit'},
        {'script': 'Moon',      'roman': 'Moon',      'english': 'Shines at night'},
      ],
      'N': [
        {'script': 'Nest',      'roman': 'Nest',      'english': 'A bird\'s home'},
        {'script': 'Nose',      'roman': 'Nose',      'english': 'Used to smell'},
      ],
      'P': [
        {'script': 'Parrot',    'roman': 'Parrot',    'english': 'A colourful bird'},
        {'script': 'Pot',       'roman': 'Pot',       'english': 'Used for cooking'},
      ],
      'Q': [
        {'script': 'Queen',     'roman': 'Queen',     'english': 'Rules a kingdom'},
        {'script': 'Quill',     'roman': 'Quill',     'english': 'A feather pen'},
      ],
      'R': [
        {'script': 'Rabbit',    'roman': 'Rabbit',    'english': 'A furry animal'},
        {'script': 'Rose',      'roman': 'Rose',      'english': 'A beautiful flower'},
      ],
      'S': [
        {'script': 'Sun',       'roman': 'Sun',       'english': 'Gives light and heat'},
        {'script': 'Star',      'roman': 'Star',      'english': 'Shines in the sky'},
      ],
      'T': [
        {'script': 'Tiger',     'roman': 'Tiger',     'english': 'A striped big cat'},
        {'script': 'Tree',      'roman': 'Tree',      'english': 'Has leaves and roots'},
      ],
      'V': [
        {'script': 'Van',       'roman': 'Van',       'english': 'A large vehicle'},
        {'script': 'Vase',      'roman': 'Vase',      'english': 'Holds flowers'},
      ],
      'W': [
        {'script': 'Water',     'roman': 'Water',     'english': 'We drink it'},
        {'script': 'Wolf',      'roman': 'Wolf',      'english': 'A wild animal'},
      ],
      'X': [
        {'script': 'Xylophone', 'roman': 'Xylophone', 'english': 'A musical instrument'},
      ],
      'Y': [
        {'script': 'Yak',       'roman': 'Yak',       'english': 'A mountain animal'},
        {'script': 'Yarn',      'roman': 'Yarn',      'english': 'A thread for knitting'},
      ],
      'Z': [
        {'script': 'Zebra',     'roman': 'Zebra',     'english': 'A striped animal'},
        {'script': 'Zoo',       'roman': 'Zoo',       'english': 'Where animals live'},
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

  Future<void> _seedHindi(Database db) async {
    final langId = await db.insert('languages', {
      'code': 'hi',
      'name': 'Hindi',
      'script': 'ह',
      'total_letters': 49,
    });

    const letters = _hindiLetterDefs;
    for (int i = 0; i < letters.length; i++) {
      final def = letters[i];
      await db.insert('letters', {
        'lang_id': langId,
        'unicode': def['unicode'],
        'romanized': def['romanized'],
        'audio_file': 'assets/audio/${def['audio']}',
        'sort_order': i + 1,
      });
    }

    await _seedHindiWordExamples(db);
  }

  Future<void> _seedHindiWordExamples(Database db) async {
    final letters = await db.query('letters',
        where: "lang_id = (SELECT id FROM languages WHERE code = 'hi')",
        orderBy: 'sort_order');

    const wordData = <String, List<Map<String, String>>>{
      'अ': [
        {'script': 'अनार',  'roman': 'anaar',  'english': 'Pomegranate'},
        {'script': 'अजगर', 'roman': 'ajgar',  'english': 'Python snake'},
      ],
      'आ': [
        {'script': 'आम',   'roman': 'aam',    'english': 'Mango'},
        {'script': 'आँख',  'roman': 'aankh',  'english': 'Eye'},
      ],
      'इ': [
        {'script': 'इमली', 'roman': 'imli',   'english': 'Tamarind'},
        {'script': 'इनाम', 'roman': 'inaam',  'english': 'Prize'},
      ],
      'ई': [
        {'script': 'ईख',  'roman': 'eekh',   'english': 'Sugarcane'},
        {'script': 'ईद',  'roman': 'eed',    'english': 'A festival'},
      ],
      'उ': [
        {'script': 'उल्लू',   'roman': 'ullu',   'english': 'Owl'},
        {'script': 'उँगली',  'roman': 'ungli',  'english': 'Finger'},
      ],
      'ऊ': [
        {'script': 'ऊन',  'roman': 'oon',    'english': 'Wool'},
        {'script': 'ऊँट', 'roman': 'oont',   'english': 'Camel'},
      ],
      'ऋ': [
        {'script': 'ऋषि', 'roman': 'rishi',  'english': 'Sage'},
        {'script': 'ऋतु', 'roman': 'ritu',   'english': 'Season'},
      ],
      'ए': [
        {'script': 'एक',    'roman': 'ek',     'english': 'One'},
        {'script': 'एड़ी',  'roman': 'edhi',   'english': 'Heel'},
      ],
      'ऐ': [
        {'script': 'ऐनक',  'roman': 'ainak',  'english': 'Spectacles'},
      ],
      'ओ': [
        {'script': 'ओस',   'roman': 'os',     'english': 'Dew'},
        {'script': 'ओखल', 'roman': 'okhal',  'english': 'Mortar'},
      ],
      'औ': [
        {'script': 'औरत',  'roman': 'aurat',  'english': 'Woman'},
        {'script': 'औज़ार', 'roman': 'auzaar', 'english': 'Tool'},
      ],
      'अं': [
        {'script': 'अंगूर', 'roman': 'angoor', 'english': 'Grapes'},
      ],
      'अः': [
        {'script': 'अः',   'roman': 'ah',     'english': 'Visarga mark'},
      ],
      'क': [
        {'script': 'कमल',  'roman': 'kamal',  'english': 'Lotus'},
        {'script': 'कबूतर', 'roman': 'kabutar', 'english': 'Pigeon'},
      ],
      'ख': [
        {'script': 'खरगोश', 'roman': 'khargosh', 'english': 'Rabbit'},
        {'script': 'खाना',  'roman': 'khaana',   'english': 'Food'},
      ],
      'ग': [
        {'script': 'गाय',  'roman': 'gaay',   'english': 'Cow'},
        {'script': 'गुलाब', 'roman': 'gulaab', 'english': 'Rose'},
      ],
      'घ': [
        {'script': 'घर',   'roman': 'ghar',   'english': 'House'},
        {'script': 'घड़ी', 'roman': 'ghadi',  'english': 'Watch'},
      ],
      'ङ': [
        {'script': 'पंग',  'roman': 'pang',   'english': 'Pang'},
      ],
      'च': [
        {'script': 'चाँद', 'roman': 'chaand', 'english': 'Moon'},
        {'script': 'चूहा', 'roman': 'chooha', 'english': 'Mouse'},
      ],
      'छ': [
        {'script': 'छाता', 'roman': 'chhaata', 'english': 'Umbrella'},
        {'script': 'छत',   'roman': 'chhat',   'english': 'Roof'},
      ],
      'ज': [
        {'script': 'जल',   'roman': 'jal',    'english': 'Water'},
        {'script': 'जहाज', 'roman': 'jahaaj', 'english': 'Ship'},
      ],
      'झ': [
        {'script': 'झरना', 'roman': 'jharna', 'english': 'Waterfall'},
        {'script': 'झंडा', 'roman': 'jhanda', 'english': 'Flag'},
      ],
      'ञ': [
        {'script': 'ज्ञान', 'roman': 'gyaan',  'english': 'Knowledge'},
      ],
      'ट': [
        {'script': 'टमाटर', 'roman': 'tamatar', 'english': 'Tomato'},
        {'script': 'टोपी',  'roman': 'topi',    'english': 'Cap'},
      ],
      'ठ': [
        {'script': 'ठंड',  'roman': 'thand',  'english': 'Cold weather'},
        {'script': 'ठेला', 'roman': 'thela',  'english': 'Cart'},
      ],
      'ड': [
        {'script': 'डमरू', 'roman': 'damru',  'english': 'Drum'},
        {'script': 'डाल',  'roman': 'daal',   'english': 'Branch'},
      ],
      'ढ': [
        {'script': 'ढोल',  'roman': 'dhol',   'english': 'Drum'},
        {'script': 'ढक्कन', 'roman': 'dhakkan', 'english': 'Lid'},
      ],
      'ण': [
        {'script': 'गणेश', 'roman': 'ganesh', 'english': 'Lord Ganesha'},
      ],
      'त': [
        {'script': 'तोता', 'roman': 'tota',   'english': 'Parrot'},
        {'script': 'तारा', 'roman': 'tara',   'english': 'Star'},
      ],
      'थ': [
        {'script': 'थैला', 'roman': 'thaila', 'english': 'Bag'},
        {'script': 'थाली', 'roman': 'thaali', 'english': 'Plate'},
      ],
      'द': [
        {'script': 'दरवाज़ा', 'roman': 'darwaza', 'english': 'Door'},
        {'script': 'दूध',    'roman': 'doodh',   'english': 'Milk'},
      ],
      'ध': [
        {'script': 'धनुष', 'roman': 'dhanush', 'english': 'Bow'},
        {'script': 'धरती', 'roman': 'dharti',  'english': 'Earth'},
      ],
      'न': [
        {'script': 'नदी',  'roman': 'nadi',   'english': 'River'},
        {'script': 'नाव',  'roman': 'naav',   'english': 'Boat'},
      ],
      'प': [
        {'script': 'पानी', 'roman': 'paani',  'english': 'Water'},
        {'script': 'पहाड़', 'roman': 'pahaad', 'english': 'Mountain'},
      ],
      'फ': [
        {'script': 'फूल',  'roman': 'phool',  'english': 'Flower'},
        {'script': 'फल',   'roman': 'phal',   'english': 'Fruit'},
      ],
      'ब': [
        {'script': 'बकरी', 'roman': 'bakri',  'english': 'Goat'},
        {'script': 'बादल', 'roman': 'baadal', 'english': 'Cloud'},
      ],
      'भ': [
        {'script': 'भालू', 'roman': 'bhaalu', 'english': 'Bear'},
        {'script': 'भाई',  'roman': 'bhaai',  'english': 'Brother'},
      ],
      'म': [
        {'script': 'मछली', 'roman': 'machhli', 'english': 'Fish'},
        {'script': 'माँ',  'roman': 'maa',     'english': 'Mother'},
      ],
      'य': [
        {'script': 'यात्रा', 'roman': 'yaatra', 'english': 'Journey'},
        {'script': 'यंत्र',  'roman': 'yantra', 'english': 'Machine'},
      ],
      'र': [
        {'script': 'रोटी', 'roman': 'roti',   'english': 'Bread'},
        {'script': 'राजा', 'roman': 'raja',   'english': 'King'},
      ],
      'ल': [
        {'script': 'लड्डू', 'roman': 'laddoo', 'english': 'Sweet ball'},
        {'script': 'लोमड़ी', 'roman': 'lomdi',  'english': 'Fox'},
      ],
      'व': [
        {'script': 'वर्षा', 'roman': 'varsha', 'english': 'Rain'},
        {'script': 'वायु',  'roman': 'vaayu',  'english': 'Wind'},
      ],
      'श': [
        {'script': 'शेर',   'roman': 'sher',   'english': 'Lion'},
        {'script': 'शहद',   'roman': 'shahad', 'english': 'Honey'},
      ],
      'ष': [
        {'script': 'षट्कोण', 'roman': 'shatkona', 'english': 'Hexagon'},
      ],
      'स': [
        {'script': 'सूरज', 'roman': 'sooraj', 'english': 'Sun'},
        {'script': 'सेब',  'roman': 'seb',    'english': 'Apple'},
      ],
      'ह': [
        {'script': 'हाथी', 'roman': 'haathi', 'english': 'Elephant'},
        {'script': 'हिरण', 'roman': 'hiran',  'english': 'Deer'},
      ],
      'क्ष': [
        {'script': 'क्षमा',  'roman': 'kshama',   'english': 'Forgiveness'},
        {'script': 'क्षत्रिय', 'roman': 'kshatriya', 'english': 'Warrior'},
      ],
      'त्र': [
        {'script': 'त्रिभुज', 'roman': 'tribhuj', 'english': 'Triangle'},
        {'script': 'त्रिशूल', 'roman': 'trishul', 'english': 'Trident'},
      ],
      'ज्ञ': [
        {'script': 'ज्ञान',  'roman': 'gyaan',  'english': 'Knowledge'},
        {'script': 'ज्ञानी', 'roman': 'gyaani', 'english': 'Wise person'},
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

  Future<void> _seedWordExamples(Database db) async {
    final letters = await db.rawQuery('''
      SELECT l.* FROM letters l
      JOIN languages lang ON l.lang_id = lang.id
      WHERE lang.code = 'or'
      ORDER BY l.sort_order
    ''');
    for (final letter in letters) {
      final unicode = letter['unicode'] as String;
      final words = _odiaWordData[unicode];
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

  // ---------------------------------------------------------------------------
  // Odia word examples (vowels + consonants) — used by seed & migration
  // ---------------------------------------------------------------------------

  static const Map<String, List<Map<String, String>>> _odiaWordData = {
    // Vowels
    'ଅ': [
      {'script': 'ଅଙ୍କ',   'roman': 'anka',     'english': 'Number'},
      {'script': 'ଅଜ',     'roman': 'aja',      'english': 'Goat'},
    ],
    'ଆ': [
      {'script': 'ଆମ',     'roman': 'aama',     'english': 'Mango'},
      {'script': 'ଆଖି',    'roman': 'aakhi',    'english': 'Eye'},
    ],
    'ଇ': [
      {'script': 'ଇଟ',     'roman': 'ita',      'english': 'Brick'},
      {'script': 'ଇଲିଶ',  'roman': 'ilish',    'english': 'Hilsa fish'},
    ],
    'ଈ': [
      {'script': 'ଈଶ',     'roman': 'isha',     'english': 'God'},
      {'script': 'ଈଶ୍ୱର', 'roman': 'ishwar',   'english': 'Lord'},
    ],
    'ଉ': [
      {'script': 'ଉଟ',     'roman': 'uta',      'english': 'Camel'},
      {'script': 'ଉଲୁ',    'roman': 'ulu',      'english': 'Owl'},
    ],
    'ଊ': [
      {'script': 'ଊଷା',    'roman': 'usha',     'english': 'Dawn'},
      {'script': 'ଊର୍ମି',  'roman': 'urmi',     'english': 'Wave'},
    ],
    'ଋ': [
      {'script': 'ଋଷି',    'roman': 'rushi',    'english': 'Sage'},
      {'script': 'ଋତୁ',    'roman': 'rutu',     'english': 'Season'},
    ],
    'ଏ': [
      {'script': 'ଏକ',     'roman': 'eka',      'english': 'One'},
      {'script': 'ଏକତା',   'roman': 'ekata',    'english': 'Unity'},
    ],
    'ଐ': [
      {'script': 'ଐରାବତ', 'roman': 'airavata', 'english': 'Divine elephant'},
    ],
    'ଓ': [
      {'script': 'ଓଡ଼ିଆ',  'roman': 'odia',     'english': 'Odia language'},
      {'script': 'ଓଷ୍ଠ',   'roman': 'oshtha',   'english': 'Lip'},
    ],
    'ଔ': [
      {'script': 'ଔଷଧ',    'roman': 'aushadha', 'english': 'Medicine'},
    ],
    'ଅଂ': [
      {'script': 'ଅଂଶ',    'roman': 'ansha',    'english': 'Part'},
    ],
    'ଅଃ': [
      {'script': 'ଅଃ',     'roman': 'ah',       'english': 'Visarga mark'},
    ],
    // Consonants
    'କ': [
      {'script': 'କମଳ',    'roman': 'kamala',   'english': 'Lotus'},
      {'script': 'କବୁତର',  'roman': 'kabutara', 'english': 'Pigeon'},
    ],
    'ଖ': [
      {'script': 'ଖରଗୋଶ', 'roman': 'kharagosh','english': 'Rabbit'},
      {'script': 'ଖଜୁର',   'roman': 'khajura',  'english': 'Date fruit'},
    ],
    'ଗ': [
      {'script': 'ଗାଈ',    'roman': 'gai',      'english': 'Cow'},
      {'script': 'ଗୋଲାପ',  'roman': 'golapa',   'english': 'Rose'},
    ],
    'ଘ': [
      {'script': 'ଘର',     'roman': 'ghara',    'english': 'House'},
      {'script': 'ଘଣ୍ଟା',  'roman': 'ghanta',   'english': 'Bell'},
    ],
    'ଙ': [
      {'script': 'ଅଙ୍ଗ',   'roman': 'anga',     'english': 'Limb'},
    ],
    'ଚ': [
      {'script': 'ଚଢ଼େଇ',  'roman': 'chadhei',  'english': 'Sparrow'},
      {'script': 'ଚଉଳ',    'roman': 'chaula',   'english': 'Rice'},
    ],
    'ଛ': [
      {'script': 'ଛତା',    'roman': 'chhata',   'english': 'Umbrella'},
      {'script': 'ଛଳ',     'roman': 'chhala',   'english': 'Trick'},
    ],
    'ଜ': [
      {'script': 'ଜଳ',     'roman': 'jala',     'english': 'Water'},
      {'script': 'ଜାହାଜ',  'roman': 'jahaja',   'english': 'Ship'},
    ],
    'ଝ': [
      {'script': 'ଝରଣା',   'roman': 'jharana',  'english': 'Waterfall'},
      {'script': 'ଝିଅ',    'roman': 'jhia',     'english': 'Girl'},
    ],
    'ଞ': [
      {'script': 'ଅଞ୍ଚଳ',  'roman': 'anchala',  'english': 'Region'},
    ],
    'ଟ': [
      {'script': 'ଟମାଟୋ',  'roman': 'tamato',   'english': 'Tomato'},
      {'script': 'ଟୋପି',   'roman': 'topi',     'english': 'Cap'},
    ],
    'ଠ': [
      {'script': 'ଠୋଙ୍ଗା', 'roman': 'thonga',   'english': 'Beak'},
      {'script': 'ଠାଣ',    'roman': 'thana',    'english': 'Place'},
    ],
    'ଡ': [
      {'script': 'ଡଙ୍ଗା',  'roman': 'danga',    'english': 'Boat'},
      {'script': 'ଡାଳ',    'roman': 'dala',     'english': 'Branch'},
    ],
    'ଢ': [
      {'script': 'ଢୋଲ',    'roman': 'dhola',    'english': 'Drum'},
      {'script': 'ଢଗ',     'roman': 'dhaga',    'english': 'Thread'},
    ],
    'ଣ': [
      {'script': 'ଗଣେଶ',   'roman': 'ganesha',  'english': 'Lord Ganesha'},
    ],
    'ତ': [
      {'script': 'ତୋତା',   'roman': 'tota',     'english': 'Parrot'},
      {'script': 'ତାରା',   'roman': 'tara',     'english': 'Star'},
    ],
    'ଥ': [
      {'script': 'ଥାଳି',   'roman': 'thali',    'english': 'Plate'},
      {'script': 'ଥଳ',     'roman': 'thala',    'english': 'Land'},
    ],
    'ଦ': [
      {'script': 'ଦର୍ପଣ',  'roman': 'darpana',  'english': 'Mirror'},
      {'script': 'ଦୁଧ',    'roman': 'dudha',    'english': 'Milk'},
    ],
    'ଧ': [
      {'script': 'ଧନୁ',    'roman': 'dhanu',    'english': 'Bow'},
      {'script': 'ଧରା',    'roman': 'dhara',    'english': 'Earth'},
    ],
    'ନ': [
      {'script': 'ନଈ',     'roman': 'nai',      'english': 'River'},
      {'script': 'ନାଉ',    'roman': 'nau',      'english': 'Boat'},
    ],
    'ପ': [
      {'script': 'ପଦ୍ମ',   'roman': 'padma',    'english': 'Lotus'},
      {'script': 'ପକ୍ଷୀ',  'roman': 'pakshi',   'english': 'Bird'},
    ],
    'ଫ': [
      {'script': 'ଫୁଲ',    'roman': 'phula',    'english': 'Flower'},
      {'script': 'ଫଳ',     'roman': 'phala',    'english': 'Fruit'},
    ],
    'ବ': [
      {'script': 'ବାଘ',    'roman': 'bagha',    'english': 'Tiger'},
      {'script': 'ବ୍ୟାଙ୍ଗ','roman': 'byanga',   'english': 'Frog'},
    ],
    'ଭ': [
      {'script': 'ଭାଲୁ',   'roman': 'bhalu',    'english': 'Bear'},
      {'script': 'ଭ୍ରମର',  'roman': 'bhramara', 'english': 'Bee'},
    ],
    'ମ': [
      {'script': 'ମାଛ',    'roman': 'macha',    'english': 'Fish'},
      {'script': 'ମୋର',    'roman': 'mora',     'english': 'Peacock'},
    ],
    'ଯ': [
      {'script': 'ଯାତ୍ରା', 'roman': 'yatra',    'english': 'Journey'},
      {'script': 'ଯଜ୍ଞ',   'roman': 'yajna',    'english': 'Ritual'},
    ],
    'ର': [
      {'script': 'ରାଜା',   'roman': 'raja',     'english': 'King'},
      {'script': 'ରଥ',     'roman': 'ratha',    'english': 'Chariot'},
    ],
    'ଲ': [
      {'script': 'ଲଡ଼ୁ',   'roman': 'ladu',     'english': 'Sweet ball'},
      {'script': 'ଲକ୍ଷ୍ମୀ','roman': 'lakshmi',  'english': 'Goddess Lakshmi'},
    ],
    'ଵ': [
      {'script': 'ଵଂଶ',    'roman': 'vamsha',   'english': 'Bamboo'},
    ],
    'ଶ': [
      {'script': 'ଶଙ୍ଖ',   'roman': 'shankha',  'english': 'Conch shell'},
      {'script': 'ଶେର',    'roman': 'shera',    'english': 'Lion'},
    ],
    'ଷ': [
      {'script': 'ଷୋଳ',    'roman': 'shola',    'english': 'Sixteen'},
    ],
    'ସ': [
      {'script': 'ସୂର୍ଯ୍ୟ','roman': 'surya',    'english': 'Sun'},
      {'script': 'ସିଂହ',   'roman': 'simha',    'english': 'Lion'},
    ],
    'ହ': [
      {'script': 'ହାତୀ',   'roman': 'hati',     'english': 'Elephant'},
      {'script': 'ହରିଣ',   'roman': 'harina',   'english': 'Deer'},
    ],
    'ଳ': [
      {'script': 'ଅଳଙ୍କାର','roman': 'alankara', 'english': 'Jewellery'},
    ],
    'କ୍ଷ': [
      {'script': 'କ୍ଷୀର',  'roman': 'kshira',   'english': 'Milk'},
      {'script': 'କ୍ଷେତ',  'roman': 'kheta',    'english': 'Field'},
    ],
    'ଜ୍ଞ': [
      {'script': 'ଜ୍ଞାନ',  'roman': 'jnana',    'english': 'Knowledge'},
    ],
  };

  // ---------------------------------------------------------------------------
  // Hindi letter definitions  (Devanagari — 13 vowels + 36 consonants = 49)
  // ---------------------------------------------------------------------------

  static const List<Map<String, String>> _hindiLetterDefs = [
    // Vowels (sort_order 1–13)
    {'unicode': 'अ',  'romanized': 'A',    'audio': 'hi_vowel_a.mp3'},
    {'unicode': 'आ',  'romanized': 'Aa',   'audio': 'hi_vowel_aa.mp3'},
    {'unicode': 'इ',  'romanized': 'I',    'audio': 'hi_vowel_i.mp3'},
    {'unicode': 'ई',  'romanized': 'Ii',   'audio': 'hi_vowel_ii.mp3'},
    {'unicode': 'उ',  'romanized': 'U',    'audio': 'hi_vowel_u.mp3'},
    {'unicode': 'ऊ',  'romanized': 'Uu',   'audio': 'hi_vowel_uu.mp3'},
    {'unicode': 'ऋ',  'romanized': 'Ri',   'audio': 'hi_vowel_ri.mp3'},
    {'unicode': 'ए',  'romanized': 'E',    'audio': 'hi_vowel_e.mp3'},
    {'unicode': 'ऐ',  'romanized': 'Ai',   'audio': 'hi_vowel_ai.mp3'},
    {'unicode': 'ओ',  'romanized': 'O',    'audio': 'hi_vowel_o.mp3'},
    {'unicode': 'औ',  'romanized': 'Au',   'audio': 'hi_vowel_au.mp3'},
    {'unicode': 'अं', 'romanized': 'Am',   'audio': 'hi_vowel_am.mp3'},
    {'unicode': 'अः', 'romanized': 'Ah',   'audio': 'hi_vowel_ah.mp3'},
    // Consonants (sort_order 14–49)
    {'unicode': 'क',   'romanized': 'Ka',   'audio': 'hi_consonant_ka.mp3'},
    {'unicode': 'ख',   'romanized': 'Kha',  'audio': 'hi_consonant_kha.mp3'},
    {'unicode': 'ग',   'romanized': 'Ga',   'audio': 'hi_consonant_ga.mp3'},
    {'unicode': 'घ',   'romanized': 'Gha',  'audio': 'hi_consonant_gha.mp3'},
    {'unicode': 'ङ',   'romanized': 'Nga',  'audio': 'hi_consonant_nga.mp3'},
    {'unicode': 'च',   'romanized': 'Cha',  'audio': 'hi_consonant_cha.mp3'},
    {'unicode': 'छ',   'romanized': 'Chha', 'audio': 'hi_consonant_chha.mp3'},
    {'unicode': 'ज',   'romanized': 'Ja',   'audio': 'hi_consonant_ja.mp3'},
    {'unicode': 'झ',   'romanized': 'Jha',  'audio': 'hi_consonant_jha.mp3'},
    {'unicode': 'ञ',   'romanized': 'Nya',  'audio': 'hi_consonant_nya.mp3'},
    {'unicode': 'ट',   'romanized': 'Ta',   'audio': 'hi_consonant_ta.mp3'},
    {'unicode': 'ठ',   'romanized': 'Tha',  'audio': 'hi_consonant_tha.mp3'},
    {'unicode': 'ड',   'romanized': 'Da',   'audio': 'hi_consonant_da.mp3'},
    {'unicode': 'ढ',   'romanized': 'Dha',  'audio': 'hi_consonant_dha.mp3'},
    {'unicode': 'ण',   'romanized': 'Na',   'audio': 'hi_consonant_na.mp3'},
    {'unicode': 'त',   'romanized': 'Ta',   'audio': 'hi_consonant_ta2.mp3'},
    {'unicode': 'थ',   'romanized': 'Tha',  'audio': 'hi_consonant_tha2.mp3'},
    {'unicode': 'द',   'romanized': 'Da',   'audio': 'hi_consonant_da2.mp3'},
    {'unicode': 'ध',   'romanized': 'Dha',  'audio': 'hi_consonant_dha2.mp3'},
    {'unicode': 'न',   'romanized': 'Na',   'audio': 'hi_consonant_na2.mp3'},
    {'unicode': 'प',   'romanized': 'Pa',   'audio': 'hi_consonant_pa.mp3'},
    {'unicode': 'फ',   'romanized': 'Pha',  'audio': 'hi_consonant_pha.mp3'},
    {'unicode': 'ब',   'romanized': 'Ba',   'audio': 'hi_consonant_ba.mp3'},
    {'unicode': 'भ',   'romanized': 'Bha',  'audio': 'hi_consonant_bha.mp3'},
    {'unicode': 'म',   'romanized': 'Ma',   'audio': 'hi_consonant_ma.mp3'},
    {'unicode': 'य',   'romanized': 'Ya',   'audio': 'hi_consonant_ya.mp3'},
    {'unicode': 'र',   'romanized': 'Ra',   'audio': 'hi_consonant_ra.mp3'},
    {'unicode': 'ल',   'romanized': 'La',   'audio': 'hi_consonant_la.mp3'},
    {'unicode': 'व',   'romanized': 'Va',   'audio': 'hi_consonant_va.mp3'},
    {'unicode': 'श',   'romanized': 'Sha',  'audio': 'hi_consonant_sha.mp3'},
    {'unicode': 'ष',   'romanized': 'Ssa',  'audio': 'hi_consonant_ssa.mp3'},
    {'unicode': 'स',   'romanized': 'Sa',   'audio': 'hi_consonant_sa.mp3'},
    {'unicode': 'ह',   'romanized': 'Ha',   'audio': 'hi_consonant_ha.mp3'},
    {'unicode': 'क्ष', 'romanized': 'Ksha', 'audio': 'hi_consonant_ksha.mp3'},
    {'unicode': 'त्र', 'romanized': 'Tra',  'audio': 'hi_consonant_tra.mp3'},
    {'unicode': 'ज्ञ', 'romanized': 'Gya',  'audio': 'hi_consonant_gya.mp3'},
  ];

  // ---------------------------------------------------------------------------
  // English letter definitions
  // ---------------------------------------------------------------------------

  static const List<Map<String, String>> _englishLetterDefs = [
    // Vowels (sort_order 1–5)
    {'unicode': 'A', 'romanized': 'A', 'audio': 'letter_a.mp3'},
    {'unicode': 'E', 'romanized': 'E', 'audio': 'letter_e.mp3'},
    {'unicode': 'I', 'romanized': 'I', 'audio': 'letter_i.mp3'},
    {'unicode': 'O', 'romanized': 'O', 'audio': 'letter_o.mp3'},
    {'unicode': 'U', 'romanized': 'U', 'audio': 'letter_u.mp3'},
    // Consonants (sort_order 6–26)
    {'unicode': 'B', 'romanized': 'B', 'audio': 'letter_b.mp3'},
    {'unicode': 'C', 'romanized': 'C', 'audio': 'letter_c.mp3'},
    {'unicode': 'D', 'romanized': 'D', 'audio': 'letter_d.mp3'},
    {'unicode': 'F', 'romanized': 'F', 'audio': 'letter_f.mp3'},
    {'unicode': 'G', 'romanized': 'G', 'audio': 'letter_g.mp3'},
    {'unicode': 'H', 'romanized': 'H', 'audio': 'letter_h.mp3'},
    {'unicode': 'J', 'romanized': 'J', 'audio': 'letter_j.mp3'},
    {'unicode': 'K', 'romanized': 'K', 'audio': 'letter_k.mp3'},
    {'unicode': 'L', 'romanized': 'L', 'audio': 'letter_l.mp3'},
    {'unicode': 'M', 'romanized': 'M', 'audio': 'letter_m.mp3'},
    {'unicode': 'N', 'romanized': 'N', 'audio': 'letter_n.mp3'},
    {'unicode': 'P', 'romanized': 'P', 'audio': 'letter_p.mp3'},
    {'unicode': 'Q', 'romanized': 'Q', 'audio': 'letter_q.mp3'},
    {'unicode': 'R', 'romanized': 'R', 'audio': 'letter_r.mp3'},
    {'unicode': 'S', 'romanized': 'S', 'audio': 'letter_s.mp3'},
    {'unicode': 'T', 'romanized': 'T', 'audio': 'letter_t.mp3'},
    {'unicode': 'V', 'romanized': 'V', 'audio': 'letter_v.mp3'},
    {'unicode': 'W', 'romanized': 'W', 'audio': 'letter_w.mp3'},
    {'unicode': 'X', 'romanized': 'X', 'audio': 'letter_x.mp3'},
    {'unicode': 'Y', 'romanized': 'Y', 'audio': 'letter_y.mp3'},
    {'unicode': 'Z', 'romanized': 'Z', 'audio': 'letter_z.mp3'},
  ];
}
