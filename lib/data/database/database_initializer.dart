// lib/data/database/database_initializer.dart
//
// Call DatabaseInitializer.initialize() once at app start (e.g. in main.dart
// before runApp). It runs all seeders in order and is fully idempotent —
// safe to call on every launch.
//
// To add a new language seeder later, just append it to the list inside
// _runSeeders().

import 'database_helper.dart';
import 'odia_seeder.dart';

class DatabaseInitializer {
  DatabaseInitializer._();

  static Future<void> initialize() async {
    final db = DatabaseHelper.instance;

    // Ensures the database file is created and schema is up-to-date
    // before any seeder tries to write rows.
    await db.database;

    await _runSeeders(db);
  }

  static Future<void> _runSeeders(DatabaseHelper db) async {
    await OdiaLanguageSeeder.seed(db);
    // Future languages:
    // await HindiLanguageSeeder.seed(db);
    // await BengaliLanguageSeeder.seed(db);
  }
}
