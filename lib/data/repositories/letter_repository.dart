// lib/data/repositories/letter_repository.dart

import '../database/database_helper.dart';
import '../models/letter_model.dart';
import '../models/progress_model.dart';
import 'progress_repository.dart';

class LetterRepository {
  final DatabaseHelper _db;
  final ProgressRepository _progressRepo;

  LetterRepository({
    DatabaseHelper? db,
    ProgressRepository? progressRepo,
  })  : _db = db ?? DatabaseHelper.instance,
        _progressRepo = progressRepo ?? ProgressRepository();

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns all letters for [languageId] sorted by [display_order].
  Future<List<LetterModel>> getLettersByLanguage(int languageId) async {
    final rows = await _db.queryWhere(
      DatabaseHelper.tableLetters,
      where: 'language_id = ?',
      whereArgs: [languageId],
      orderBy: 'display_order ASC',
    );
    return rows.map(LetterModel.fromMap).toList();
  }

  /// Returns the letter with [id], or `null` if not found.
  Future<LetterModel?> getLetterById(int id) async {
    final row = await _db.queryOne(
      DatabaseHelper.tableLetters,
      where: 'id = ?',
      whereArgs: [id],
    );
    return row != null ? LetterModel.fromMap(row) : null;
  }

  /// Returns letters for [languageId] in the given [masteryLevel] for [childId].
  ///
  /// Useful for showing "ready to practice" or "mastered" subsets.
  Future<List<LetterModel>> getLettersByMastery(
    int languageId,
    int childId,
    MasteryLevel masteryLevel,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT l.*
      FROM ${DatabaseHelper.tableLetters} l
      LEFT JOIN ${DatabaseHelper.tableProgress} p
        ON p.letter_id = l.id AND p.child_id = ?
      WHERE l.language_id = ?
        AND COALESCE(p.mastery_level, 0) = ?
      ORDER BY l.display_order ASC
      ''',
      [childId, languageId, masteryLevel.value],
    );
    return rows.map(LetterModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Convenience wrapper: records a practice session outcome for [childId] on
  /// [letterId]. Delegates to [ProgressRepository.upsertProgress] after
  /// computing the new accuracy running average.
  ///
  /// [sessionAccuracy] — raw accuracy for this session in [0.0, 100.0].
  /// [sessionStars]    — stars earned in this session (0-3).
  Future<ProgressModel> updateProgress({
    required int childId,
    required int letterId,
    required MasteryLevel newMasteryLevel,
    required double sessionAccuracy,
    required int sessionStars,
  }) async {
    final existing =
        await _progressRepo.getProgressForLetter(childId, letterId);

    final int attempts = (existing?.attempts ?? 0) + 1;
    final int prevStars = existing?.starsEarned ?? 0;
    final int newStars =
        sessionStars > prevStars ? sessionStars : prevStars; // keep best

    // Running average accuracy
    final double prevAccuracy = existing?.accuracyScore ?? 0.0;
    final double newAccuracy =
        ((prevAccuracy * (attempts - 1)) + sessionAccuracy) / attempts;

    final updated = ProgressModel(
      id: existing?.id,
      childId: childId,
      letterId: letterId,
      masteryLevel: newMasteryLevel,
      attempts: attempts,
      starsEarned: newStars,
      accuracyScore: newAccuracy.clamp(0.0, 100.0),
      lastPracticed: DateTime.now().toUtc(),
    );

    return _progressRepo.upsertProgress(updated);
  }

  // ---------------------------------------------------------------------------
  // Admin helpers
  // ---------------------------------------------------------------------------

  Future<int> insertLetter(LetterModel letter) async {
    return _db.insert(DatabaseHelper.tableLetters, letter.toMap());
  }

  Future<int> updateLetter(LetterModel letter) async {
    assert(letter.id != null, 'Cannot update a letter without an id');
    return _db.update(
      DatabaseHelper.tableLetters,
      letter.toMap(),
      where: 'id = ?',
      whereArgs: [letter.id],
    );
  }

  Future<int> deleteLetter(int id) async {
    return _db.delete(
      DatabaseHelper.tableLetters,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
