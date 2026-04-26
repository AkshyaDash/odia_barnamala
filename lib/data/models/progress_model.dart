// lib/data/models/progress_model.dart

/// The learning stage a child has reached for a specific letter.
///
/// Values correspond to the `mastery_level` INTEGER column:
///   0 = locked   – not yet available
///   1 = trace    – tracing over dotted guides
///   2 = copy     – copy from a faded example
///   3 = write    – write from memory
///   4 = mastered – completed all stages with sufficient accuracy
enum MasteryLevel {
  locked(0),
  trace(1),
  copy(2),
  write(3),
  mastered(4);

  const MasteryLevel(this.value);
  final int value;

  static MasteryLevel fromValue(int v) =>
      MasteryLevel.values.firstWhere((e) => e.value == v,
          orElse: () => MasteryLevel.locked);
}

/// One row in the `progress` table — the junction between a child and a letter.
class ProgressModel {
  final int? id;
  final int childId;
  final int letterId;
  final MasteryLevel masteryLevel;
  final int attempts;
  final int starsEarned;

  /// Accuracy score in the range [0.0, 100.0].
  final double accuracyScore;

  /// Null when the letter has never been practised.
  final DateTime? lastPracticed;

  const ProgressModel({
    this.id,
    required this.childId,
    required this.letterId,
    required this.masteryLevel,
    required this.attempts,
    required this.starsEarned,
    required this.accuracyScore,
    this.lastPracticed,
  });

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      id: map['id'] as int?,
      childId: map['child_id'] as int,
      letterId: map['letter_id'] as int,
      masteryLevel: MasteryLevel.fromValue(map['mastery_level'] as int),
      attempts: map['attempts'] as int,
      starsEarned: map['stars_earned'] as int,
      accuracyScore: (map['accuracy_score'] as num).toDouble(),
      lastPracticed: map['last_practiced'] != null
          ? DateTime.parse(map['last_practiced'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'child_id': childId,
      'letter_id': letterId,
      'mastery_level': masteryLevel.value,
      'attempts': attempts,
      'stars_earned': starsEarned,
      'accuracy_score': accuracyScore,
      'last_practiced': lastPracticed?.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  ProgressModel copyWith({
    int? id,
    int? childId,
    int? letterId,
    MasteryLevel? masteryLevel,
    int? attempts,
    int? starsEarned,
    double? accuracyScore,
    DateTime? lastPracticed,
    bool clearLastPracticed = false,
  }) {
    return ProgressModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      letterId: letterId ?? this.letterId,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      attempts: attempts ?? this.attempts,
      starsEarned: starsEarned ?? this.starsEarned,
      accuracyScore: accuracyScore ?? this.accuracyScore,
      lastPracticed: clearLastPracticed
          ? null
          : (lastPracticed ?? this.lastPracticed),
    );
  }

  /// True when this letter has been unlocked for the child.
  bool get isUnlocked => masteryLevel != MasteryLevel.locked;

  @override
  String toString() => 'ProgressModel(id: $id, childId: $childId, '
      'letterId: $letterId, mastery: ${masteryLevel.name}, '
      'stars: $starsEarned, accuracy: $accuracyScore)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressModel &&
          runtimeType == other.runtimeType &&
          childId == other.childId &&
          letterId == other.letterId;

  @override
  int get hashCode => Object.hash(childId, letterId);
}
