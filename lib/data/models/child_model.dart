// lib/data/models/child_model.dart

/// Represents a learner profile stored in the `children` table.
class ChildModel {
  final int? id;
  final String name;
  final int avatarIndex;
  final int coins;
  final int totalStars;
  final int currentStreak;
  final int longestStreak;

  /// Null when the child has never opened the app.
  final DateTime? lastOpenedDate;
  final DateTime createdAt;

  const ChildModel({
    this.id,
    required this.name,
    required this.avatarIndex,
    required this.coins,
    required this.totalStars,
    required this.currentStreak,
    required this.longestStreak,
    this.lastOpenedDate,
    required this.createdAt,
  });

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      avatarIndex: map['avatar_index'] as int,
      coins: map['coins'] as int,
      totalStars: map['total_stars'] as int,
      currentStreak: map['current_streak'] as int,
      longestStreak: map['longest_streak'] as int,
      lastOpenedDate: map['last_opened_date'] != null
          ? DateTime.parse(map['last_opened_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'avatar_index': avatarIndex,
      'coins': coins,
      'total_stars': totalStars,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_opened_date': lastOpenedDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  ChildModel copyWith({
    int? id,
    String? name,
    int? avatarIndex,
    int? coins,
    int? totalStars,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastOpenedDate,
    DateTime? createdAt,
    bool clearLastOpenedDate = false,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      coins: coins ?? this.coins,
      totalStars: totalStars ?? this.totalStars,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastOpenedDate: clearLastOpenedDate
          ? null
          : (lastOpenedDate ?? this.lastOpenedDate),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'ChildModel(id: $id, name: $name, coins: $coins, '
      'totalStars: $totalStars, currentStreak: $currentStreak)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
