// lib/data/models/language_model.dart

class LanguageModel {
  final int? id;
  final String name;
  final String nativeName;

  /// e.g. 'devanagari', 'odia', 'tamil', 'arabic' (for Urdu), 'ol_chiki' …
  final String scriptFamily;
  final int totalLetters;
  final bool isUnlocked;
  final int displayOrder;

  const LanguageModel({
    this.id,
    required this.name,
    required this.nativeName,
    required this.scriptFamily,
    required this.totalLetters,
    required this.isUnlocked,
    required this.displayOrder,
  });

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory LanguageModel.fromMap(Map<String, dynamic> map) {
    return LanguageModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      nativeName: map['native_name'] as String,
      scriptFamily: map['script_family'] as String,
      totalLetters: map['total_letters'] as int,
      isUnlocked: (map['is_unlocked'] as int) == 1,
      displayOrder: map['display_order'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'native_name': nativeName,
      'script_family': scriptFamily,
      'total_letters': totalLetters,
      'is_unlocked': isUnlocked ? 1 : 0,
      'display_order': displayOrder,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  LanguageModel copyWith({
    int? id,
    String? name,
    String? nativeName,
    String? scriptFamily,
    int? totalLetters,
    bool? isUnlocked,
    int? displayOrder,
  }) {
    return LanguageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nativeName: nativeName ?? this.nativeName,
      scriptFamily: scriptFamily ?? this.scriptFamily,
      totalLetters: totalLetters ?? this.totalLetters,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  String toString() => 'LanguageModel(id: $id, name: $name, '
      'nativeName: $nativeName, scriptFamily: $scriptFamily, '
      'totalLetters: $totalLetters, isUnlocked: $isUnlocked, '
      'displayOrder: $displayOrder)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
