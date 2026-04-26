// lib/data/models/streak_model.dart

/// One row in the `streaks` table.
///
/// [streakDate] is an ISO 8601 date-only string (`YYYY-MM-DD`).
/// The UNIQUE(child_id, streak_date) constraint guarantees at most one
/// record per child per calendar day.
class StreakModel {
  final int? id;
  final int childId;

  /// Date-only string, e.g. `'2025-11-03'`.
  final String streakDate;

  const StreakModel({
    this.id,
    required this.childId,
    required this.streakDate,
  });

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory StreakModel.fromMap(Map<String, dynamic> map) {
    return StreakModel(
      id: map['id'] as int?,
      childId: map['child_id'] as int,
      streakDate: map['streak_date'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'child_id': childId,
      'streak_date': streakDate,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  StreakModel copyWith({
    int? id,
    int? childId,
    String? streakDate,
  }) {
    return StreakModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      streakDate: streakDate ?? this.streakDate,
    );
  }

  /// Parse [streakDate] into a [DateTime] at midnight local time.
  DateTime toDateTime() {
    final parts = streakDate.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  String toString() =>
      'StreakModel(id: $id, childId: $childId, streakDate: $streakDate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakModel &&
          runtimeType == other.runtimeType &&
          childId == other.childId &&
          streakDate == other.streakDate;

  @override
  int get hashCode => Object.hash(childId, streakDate);
}
