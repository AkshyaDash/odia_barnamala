// lib/data/repositories/progress_repository.dart

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/progress_model.dart';

class ProgressRepository {
  final DatabaseHelper _db;

  ProgressRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// All progress rows for [childId], ordered by letter display_order.
  Future<List<ProgressModel>> getProgressForChild(int childId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT p.*
      FROM ${DatabaseHelper.tableProgress} p
      JOIN ${DatabaseHelper.tableLetters} l ON l.id = p.letter_id
      WHERE p.child_id = ?
      ORDER BY l.display_order ASC
      ''',
      [childId],
    );
    return rows.map(ProgressModel.fromMap).toList();
  }

  /// Progress for [childId] scoped to letters belonging to [languageId].
  Future<List<ProgressModel>> getProgressForChildAndLanguage(
    int childId,
    int languageId,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT p.*
      FROM ${DatabaseHelper.tableProgress} p
      JOIN ${DatabaseHelper.tableLetters} l ON l.id = p.letter_id
      WHERE p.child_id = ? AND l.language_id = ?
      ORDER BY l.display_order ASC
      ''',
      [childId, languageId],
    );
    return rows.map(ProgressModel.fromMap).toList();
  }

  /// Progress row for a single (child, letter) pair, or `null` if absent.
  Future<ProgressModel?> getProgressForLetter(
      int childId, int letterId) async {
    final row = await _db.queryOne(
      DatabaseHelper.tableProgress,
      where: 'child_id = ? AND letter_id = ?',
      whereArgs: [childId, letterId],
    );
    return row != null ? ProgressModel.fromMap(row) : null;
  }

  /// Returns the [MasteryLevel] for [letterId] for [childId].
  /// Returns [MasteryLevel.locked] when no row exists yet.
  Future<MasteryLevel> getMasteryLevel(int childId, int letterId) async {
    final progress = await getProgressForLetter(childId, letterId);
    return progress?.masteryLevel ?? MasteryLevel.locked;
  }

  /// Number of letters at or above [threshold] mastery for [childId].
  Future<int> countAtMastery(
    int childId,
    MasteryLevel threshold,
  ) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt
      FROM ${DatabaseHelper.tableProgress}
      WHERE child_id = ? AND mastery_level >= ?
      ''',
      [childId, threshold.value],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// INSERT OR REPLACE the progress row, preserving the row id when it already
  /// exists so foreign-key references remain stable.
  ///
  /// Returns the final [ProgressModel] (with id populated).
  Future<ProgressModel> upsertProgress(ProgressModel progress) async {
    final existing =
        await getProgressForLetter(progress.childId, progress.letterId);

    if (existing == null) {
      // New row — strip id so SQLite auto-assigns one
      final newRow = progress.copyWith(id: null).toMap()..remove('id');
      final newId = await _db.insert(
        DatabaseHelper.tableProgress,
        newRow,
        conflict: ConflictAlgorithm.replace,
      );
      return progress.copyWith(id: newId);
    } else {
      // Update the existing row, preserving its id
      final updated = progress.copyWith(id: existing.id);
      await _db.update(
        DatabaseHelper.tableProgress,
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return updated;
    }
  }

  /// Resets progress for [childId] on [letterId] back to [MasteryLevel.locked].
  Future<void> resetProgress(int childId, int letterId) async {
    await _db.delete(
      DatabaseHelper.tableProgress,
      where: 'child_id = ? AND letter_id = ?',
      whereArgs: [childId, letterId],
    );
  }

  /// Deletes all progress rows for [childId] (e.g. on profile reset).
  Future<void> deleteAllProgressForChild(int childId) async {
    await _db.delete(
      DatabaseHelper.tableProgress,
      where: 'child_id = ?',
      whereArgs: [childId],
    );
  }
}
