// lib/data/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'bharat_lipi.db';
  static const _databaseVersion = 1;

  // Table name constants
  static const tableLanguages = 'languages';
  static const tableLetters = 'letters';
  static const tableChildren = 'children';
  static const tableProgress = 'progress';
  static const tableRewards = 'rewards';
  static const tableStreaks = 'streaks';

  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

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
      onConfigure: _onConfigure,
    );
  }

  // Enable foreign key enforcement on every connection
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ---------------------------------------------------------------------------
  // Schema creation
  // ---------------------------------------------------------------------------
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // languages ---------------------------------------------------------------
    batch.execute('''
      CREATE TABLE $tableLanguages (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        native_name     TEXT    NOT NULL,
        script_family   TEXT    NOT NULL,
        total_letters   INTEGER NOT NULL DEFAULT 0,
        is_unlocked     INTEGER NOT NULL DEFAULT 0,
        display_order   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // letters -----------------------------------------------------------------
    batch.execute('''
      CREATE TABLE $tableLetters (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        language_id          INTEGER NOT NULL,
        unicode_char         TEXT    NOT NULL,
        romanized            TEXT    NOT NULL,
        stroke_order_json    TEXT    NOT NULL DEFAULT '[]',
        audio_filename       TEXT,
        example_word         TEXT,
        example_word_meaning TEXT,
        display_order        INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (language_id)
          REFERENCES $tableLanguages(id) ON DELETE CASCADE
      )
    ''');

    // children ----------------------------------------------------------------
    batch.execute('''
      CREATE TABLE $tableChildren (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT    NOT NULL,
        avatar_index     INTEGER NOT NULL DEFAULT 0,
        coins            INTEGER NOT NULL DEFAULT 0,
        total_stars      INTEGER NOT NULL DEFAULT 0,
        current_streak   INTEGER NOT NULL DEFAULT 0,
        longest_streak   INTEGER NOT NULL DEFAULT 0,
        last_opened_date TEXT,
        created_at       TEXT    NOT NULL
      )
    ''');

    // progress ----------------------------------------------------------------
    batch.execute('''
      CREATE TABLE $tableProgress (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id       INTEGER NOT NULL,
        letter_id      INTEGER NOT NULL,
        mastery_level  INTEGER NOT NULL DEFAULT 0,
        attempts       INTEGER NOT NULL DEFAULT 0,
        stars_earned   INTEGER NOT NULL DEFAULT 0,
        accuracy_score REAL    NOT NULL DEFAULT 0.0,
        last_practiced TEXT,
        FOREIGN KEY (child_id)
          REFERENCES $tableChildren(id) ON DELETE CASCADE,
        FOREIGN KEY (letter_id)
          REFERENCES $tableLetters(id)  ON DELETE CASCADE,
        UNIQUE(child_id, letter_id)
      )
    ''');

    // rewards -----------------------------------------------------------------
    batch.execute('''
      CREATE TABLE $tableRewards (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id      INTEGER NOT NULL,
        reward_type   TEXT    NOT NULL,
        reward_value  INTEGER NOT NULL DEFAULT 0,
        earned_at     TEXT    NOT NULL,
        metadata_json TEXT,
        FOREIGN KEY (child_id)
          REFERENCES $tableChildren(id) ON DELETE CASCADE
      )
    ''');

    // streaks -----------------------------------------------------------------
    batch.execute('''
      CREATE TABLE $tableStreaks (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id    INTEGER NOT NULL,
        streak_date TEXT    NOT NULL,
        FOREIGN KEY (child_id)
          REFERENCES $tableChildren(id) ON DELETE CASCADE,
        UNIQUE(child_id, streak_date)
      )
    ''');

    // Indexes -----------------------------------------------------------------
    batch.execute(
        'CREATE INDEX idx_letters_language ON $tableLetters(language_id)');
    batch.execute(
        'CREATE INDEX idx_progress_child ON $tableProgress(child_id)');
    batch.execute(
        'CREATE INDEX idx_progress_letter ON $tableProgress(letter_id)');
    batch.execute(
        'CREATE INDEX idx_rewards_child ON $tableRewards(child_id)');
    batch.execute(
        'CREATE INDEX idx_streaks_child_date ON $tableStreaks(child_id, streak_date)');

    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // Schema migrations — add a new `case` per version bump
  // ---------------------------------------------------------------------------
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int v = oldVersion + 1; v <= newVersion; v++) {
      switch (v) {
        case 2:
          // Example future migration:
          // await db.execute(
          //   'ALTER TABLE $tableLetters ADD COLUMN difficulty INTEGER NOT NULL DEFAULT 1',
          // );
          break;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Generic CRUD helpers (used by repositories)
  // ---------------------------------------------------------------------------

  Future<int> insert(
    String table,
    Map<String, dynamic> row, {
    ConflictAlgorithm conflict = ConflictAlgorithm.abort,
  }) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: conflict);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table,
      {String? orderBy}) async {
    final db = await database;
    return db.query(table, orderBy: orderBy);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> queryOne(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    final rows =
        await db.query(table, where: where, whereArgs: whereArgs, limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  /// Runs [action] inside a single SQLite transaction.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  /// Closes the database. Call on app disposal if needed.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
