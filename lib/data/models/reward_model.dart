// lib/data/models/reward_model.dart

import 'dart:convert';

/// The category of a reward earned by a child.
enum RewardType {
  star('star'),
  coin('coin'),
  badge('badge'),
  sticker('sticker');

  const RewardType(this.value);
  final String value;

  static RewardType fromValue(String v) =>
      RewardType.values.firstWhere((e) => e.value == v,
          orElse: () => RewardType.star);
}

/// One row in the `rewards` table.
///
/// [metadata] is an optional free-form map that the caller can use to store
/// additional context — e.g. `{'badge_id': 'first_odia_letter'}` or
/// `{'sticker_key': 'elephant_sticker'}`. It round-trips through
/// `metadata_json` (TEXT column) via JSON encode/decode.
class RewardModel {
  final int? id;
  final int childId;
  final RewardType rewardType;
  final int rewardValue;
  final DateTime earnedAt;

  /// Free-form JSON metadata. Null when unused.
  final Map<String, dynamic>? metadata;

  const RewardModel({
    this.id,
    required this.childId,
    required this.rewardType,
    required this.rewardValue,
    required this.earnedAt,
    this.metadata,
  });

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory RewardModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? meta;
    final raw = map['metadata_json'] as String?;
    if (raw != null && raw.isNotEmpty) {
      meta = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    }

    return RewardModel(
      id: map['id'] as int?,
      childId: map['child_id'] as int,
      rewardType: RewardType.fromValue(map['reward_type'] as String),
      rewardValue: map['reward_value'] as int,
      earnedAt: DateTime.parse(map['earned_at'] as String),
      metadata: meta,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'child_id': childId,
      'reward_type': rewardType.value,
      'reward_value': rewardValue,
      'earned_at': earnedAt.toIso8601String(),
      'metadata_json': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  RewardModel copyWith({
    int? id,
    int? childId,
    RewardType? rewardType,
    int? rewardValue,
    DateTime? earnedAt,
    Map<String, dynamic>? metadata,
    bool clearMetadata = false,
  }) {
    return RewardModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      rewardType: rewardType ?? this.rewardType,
      rewardValue: rewardValue ?? this.rewardValue,
      earnedAt: earnedAt ?? this.earnedAt,
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
    );
  }

  @override
  String toString() => 'RewardModel(id: $id, childId: $childId, '
      'type: ${rewardType.name}, value: $rewardValue, '
      'earnedAt: ${earnedAt.toIso8601String()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
