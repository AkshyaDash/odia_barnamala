// lib/data/repositories/reward_repository.dart

import '../database/database_helper.dart';
import '../models/reward_model.dart';

class RewardRepository {
  final DatabaseHelper _db;

  RewardRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// All rewards for [childId], newest first.
  Future<List<RewardModel>> getRewardsForChild(int childId) async {
    final rows = await _db.queryWhere(
      DatabaseHelper.tableRewards,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'earned_at DESC',
    );
    return rows.map(RewardModel.fromMap).toList();
  }

  /// Rewards for [childId] filtered by [type], newest first.
  Future<List<RewardModel>> getRewardsForChildByType(
    int childId,
    RewardType type,
  ) async {
    final rows = await _db.queryWhere(
      DatabaseHelper.tableRewards,
      where: 'child_id = ? AND reward_type = ?',
      whereArgs: [childId, type.value],
      orderBy: 'earned_at DESC',
    );
    return rows.map(RewardModel.fromMap).toList();
  }

  /// Sum of all [RewardType.coin] values earned by [childId].
  /// (Informational — authoritative coin balance lives on [ChildModel.coins].)
  Future<int> totalCoinsEarned(int childId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(reward_value), 0) AS total
      FROM ${DatabaseHelper.tableRewards}
      WHERE child_id = ? AND reward_type = ?
      ''',
      [childId, RewardType.coin.value],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Total stars earned by [childId] across all recorded reward rows.
  Future<int> totalStarsEarned(int childId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(reward_value), 0) AS total
      FROM ${DatabaseHelper.tableRewards}
      WHERE child_id = ? AND reward_type = ?
      ''',
      [childId, RewardType.star.value],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// True if [childId] already holds the badge identified by [badgeId].
  Future<bool> hasBadge(int childId, String badgeId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT id FROM ${DatabaseHelper.tableRewards}
      WHERE child_id = ?
        AND reward_type = ?
        AND json_extract(metadata_json, '\$.badge_id') = ?
      LIMIT 1
      ''',
      [childId, RewardType.badge.value, badgeId],
    );
    return rows.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Inserts a new reward row and returns it with the assigned [id].
  Future<RewardModel> addReward(RewardModel reward) async {
    final row = reward.toMap()..remove('id');
    final id = await _db.insert(DatabaseHelper.tableRewards, row);
    return reward.copyWith(id: id);
  }

  /// Convenience method for awarding stars.
  Future<RewardModel> awardStars(
    int childId,
    int stars, {
    Map<String, dynamic>? metadata,
  }) async {
    return addReward(RewardModel(
      childId: childId,
      rewardType: RewardType.star,
      rewardValue: stars,
      earnedAt: DateTime.now().toUtc(),
      metadata: metadata,
    ));
  }

  /// Convenience method for awarding coins.
  Future<RewardModel> awardCoins(
    int childId,
    int coins, {
    Map<String, dynamic>? metadata,
  }) async {
    return addReward(RewardModel(
      childId: childId,
      rewardType: RewardType.coin,
      rewardValue: coins,
      earnedAt: DateTime.now().toUtc(),
      metadata: metadata,
    ));
  }

  /// Convenience method for granting a badge (idempotent — skips if already held).
  ///
  /// Returns the existing or newly created [RewardModel].
  Future<RewardModel?> grantBadge(
    int childId,
    String badgeId, {
    Map<String, dynamic>? extraMetadata,
  }) async {
    if (await hasBadge(childId, badgeId)) return null;

    final meta = <String, dynamic>{'badge_id': badgeId, ...?extraMetadata};
    return addReward(RewardModel(
      childId: childId,
      rewardType: RewardType.badge,
      rewardValue: 1,
      earnedAt: DateTime.now().toUtc(),
      metadata: meta,
    ));
  }

  Future<void> deleteReward(int rewardId) async {
    await _db.delete(
      DatabaseHelper.tableRewards,
      where: 'id = ?',
      whereArgs: [rewardId],
    );
  }
}
