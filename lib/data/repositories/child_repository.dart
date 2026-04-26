// lib/data/repositories/child_repository.dart

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/child_model.dart';
import '../models/streak_model.dart';

class ChildRepository {
  final DatabaseHelper _db;

  ChildRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  Future<List<ChildModel>> getAllChildren() async {
    final rows = await _db.queryAll(
      DatabaseHelper.tableChildren,
      orderBy: 'created_at ASC',
    );
    return rows.map(ChildModel.fromMap).toList();
  }

  Future<ChildModel?> getChildById(int id) async {
    final row = await _db.queryOne(
      DatabaseHelper.tableChildren,
      where: 'id = ?',
      whereArgs: [id],
    );
    return row != null ? ChildModel.fromMap(row) : null;
  }

  // ---------------------------------------------------------------------------
  // getOrCreateChild
  // ---------------------------------------------------------------------------

  /// Returns the child with [name] (case-insensitive) if one exists, otherwise
  /// creates a new profile and returns it.
  ///
  /// [avatarIndex] is only used when a new profile is created.
  Future<ChildModel> getOrCreateChild(
    String name, {
    int avatarIndex = 0,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM ${DatabaseHelper.tableChildren} '
      'WHERE LOWER(name) = LOWER(?) LIMIT 1',
      [name],
    );

    if (rows.isNotEmpty) {
      return ChildModel.fromMap(rows.first);
    }

    final now = DateTime.now().toUtc();
    final newChild = ChildModel(
      name: name,
      avatarIndex: avatarIndex,
      coins: 0,
      totalStars: 0,
      currentStreak: 0,
      longestStreak: 0,
      createdAt: now,
    );

    final id = await _db.insert(
      DatabaseHelper.tableChildren,
      newChild.toMap(),
    );
    return newChild.copyWith(id: id);
  }

  // ---------------------------------------------------------------------------
  // Streak management
  // ---------------------------------------------------------------------------

  /// Records today's activity for [childId] and updates streak counters.
  ///
  /// Uses local date (device timezone) so the "day" boundary matches what the
  /// child sees on screen. Returns the updated [ChildModel].
  Future<ChildModel> updateStreak(int childId) async {
    final child = await getChildById(childId);
    if (child == null) throw ArgumentError('Child $childId not found');

    final today = _localDateString(DateTime.now());

    // Already recorded today — nothing to do
    final existing = await _db.queryOne(
      DatabaseHelper.tableStreaks,
      where: 'child_id = ? AND streak_date = ?',
      whereArgs: [childId, today],
    );
    if (existing != null) return child;

    // Insert streak row (UNIQUE constraint is a no-op guard)
    await _db.insert(
      DatabaseHelper.tableStreaks,
      StreakModel(childId: childId, streakDate: today).toMap(),
      conflict: ConflictAlgorithm.ignore,
    );

    // Determine whether yesterday was also a streak day
    final yesterday = _localDateString(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final yesterdayRow = await _db.queryOne(
      DatabaseHelper.tableStreaks,
      where: 'child_id = ? AND streak_date = ?',
      whereArgs: [childId, yesterday],
    );

    final int newCurrentStreak =
        yesterdayRow != null ? child.currentStreak + 1 : 1;
    final int newLongestStreak = newCurrentStreak > child.longestStreak
        ? newCurrentStreak
        : child.longestStreak;

    final updated = child.copyWith(
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      lastOpenedDate: DateTime.now().toUtc(),
    );

    await _db.update(
      DatabaseHelper.tableChildren,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [childId],
    );
    return updated;
  }

  /// Returns all recorded streak dates for [childId] sorted ascending.
  Future<List<StreakModel>> getStreaks(int childId) async {
    final rows = await _db.queryWhere(
      DatabaseHelper.tableStreaks,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'streak_date ASC',
    );
    return rows.map(StreakModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Currency & stars
  // ---------------------------------------------------------------------------

  /// Adds [amount] coins to [childId]'s balance. Returns updated [ChildModel].
  Future<ChildModel> addCoins(int childId, int amount) async {
    assert(amount >= 0, 'Coin amount must be non-negative');
    final child = await _requireChild(childId);
    final updated = child.copyWith(coins: child.coins + amount);
    await _persistChild(updated);
    return updated;
  }

  /// Adds [amount] stars to [childId]'s total. Returns updated [ChildModel].
  Future<ChildModel> addStars(int childId, int amount) async {
    assert(amount >= 0, 'Star amount must be non-negative');
    final child = await _requireChild(childId);
    final updated = child.copyWith(totalStars: child.totalStars + amount);
    await _persistChild(updated);
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Full update / delete
  // ---------------------------------------------------------------------------

  Future<ChildModel> updateChild(ChildModel child) async {
    assert(child.id != null, 'Cannot update a child without an id');
    await _persistChild(child);
    return child;
  }

  Future<void> deleteChild(int childId) async {
    // Cascade delete in SQLite removes progress, rewards, streaks automatically
    // (requires PRAGMA foreign_keys = ON, set in DatabaseHelper._onConfigure)
    await _db.delete(
      DatabaseHelper.tableChildren,
      where: 'id = ?',
      whereArgs: [childId],
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<ChildModel> _requireChild(int childId) async {
    final child = await getChildById(childId);
    if (child == null) throw ArgumentError('Child $childId not found');
    return child;
  }

  Future<void> _persistChild(ChildModel child) async {
    await _db.update(
      DatabaseHelper.tableChildren,
      child.toMap(),
      where: 'id = ?',
      whereArgs: [child.id],
    );
  }

  /// Formats [dt] to a `YYYY-MM-DD` string using the **local** timezone,
  /// ensuring the streak day boundary aligns with the device clock.
  static String _localDateString(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
