// lib/data/models/letter_model.dart

import 'dart:convert';

/// One point within a stroke, expressed as normalised [0..1] coordinates so
/// the tracing painter can scale them to any canvas size.
///
/// Stored in SQLite as part of the [strokeOrderJson] TEXT column.
class StrokePoint {
  final double dx;
  final double dy;

  const StrokePoint({required this.dx, required this.dy});

  factory StrokePoint.fromMap(Map<String, dynamic> map) {
    return StrokePoint(
      dx: (map['dx'] as num).toDouble(),
      dy: (map['dy'] as num).toDouble(),
    );
  }

  Map<String, double> toMap() => {'dx': dx, 'dy': dy};

  @override
  String toString() => 'StrokePoint(dx: $dx, dy: $dy)';
}

/// A complete letter stored in the `letters` table.
///
/// [strokeOrder] is the in-memory representation of the JSON column
/// `stroke_order_json`. It is a list of strokes, where each stroke is an
/// ordered list of [StrokePoint]s.
class LetterModel {
  final int? id;
  final int languageId;
  final String unicodeChar;
  final String romanized;

  /// List of strokes → list of normalised points per stroke.
  final List<List<StrokePoint>> strokeOrder;

  final String? audioFilename;
  final String? exampleWord;
  final String? exampleWordMeaning;
  final int displayOrder;

  const LetterModel({
    this.id,
    required this.languageId,
    required this.unicodeChar,
    required this.romanized,
    required this.strokeOrder,
    this.audioFilename,
    this.exampleWord,
    this.exampleWordMeaning,
    required this.displayOrder,
  });

  // ---------------------------------------------------------------------------
  // Stroke JSON helpers
  // ---------------------------------------------------------------------------

  /// Deserialises the raw JSON string from SQLite into [List<List<StrokePoint>>].
  static List<List<StrokePoint>> _strokesFromJson(String json) {
    final outer = jsonDecode(json) as List<dynamic>;
    return outer.map((stroke) {
      final points = stroke as List<dynamic>;
      return points
          .map((p) => StrokePoint.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList();
    }).toList();
  }

  /// Serialises [List<List<StrokePoint>>] to a JSON string for SQLite storage.
  static String _strokesToJson(List<List<StrokePoint>> strokes) {
    final outer = strokes
        .map((stroke) => stroke.map((p) => p.toMap()).toList())
        .toList();
    return jsonEncode(outer);
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory LetterModel.fromMap(Map<String, dynamic> map) {
    return LetterModel(
      id: map['id'] as int?,
      languageId: map['language_id'] as int,
      unicodeChar: map['unicode_char'] as String,
      romanized: map['romanized'] as String,
      strokeOrder:
          _strokesFromJson(map['stroke_order_json'] as String? ?? '[]'),
      audioFilename: map['audio_filename'] as String?,
      exampleWord: map['example_word'] as String?,
      exampleWordMeaning: map['example_word_meaning'] as String?,
      displayOrder: map['display_order'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'language_id': languageId,
      'unicode_char': unicodeChar,
      'romanized': romanized,
      'stroke_order_json': _strokesToJson(strokeOrder),
      'audio_filename': audioFilename,
      'example_word': exampleWord,
      'example_word_meaning': exampleWordMeaning,
      'display_order': displayOrder,
    };
  }

  // Convenience: raw JSON string (useful when passing directly to painters)
  String get strokeOrderJson => _strokesToJson(strokeOrder);

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  LetterModel copyWith({
    int? id,
    int? languageId,
    String? unicodeChar,
    String? romanized,
    List<List<StrokePoint>>? strokeOrder,
    String? audioFilename,
    String? exampleWord,
    String? exampleWordMeaning,
    int? displayOrder,
  }) {
    return LetterModel(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      unicodeChar: unicodeChar ?? this.unicodeChar,
      romanized: romanized ?? this.romanized,
      strokeOrder: strokeOrder ?? this.strokeOrder,
      audioFilename: audioFilename ?? this.audioFilename,
      exampleWord: exampleWord ?? this.exampleWord,
      exampleWordMeaning: exampleWordMeaning ?? this.exampleWordMeaning,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  String toString() => 'LetterModel(id: $id, unicodeChar: $unicodeChar, '
      'languageId: $languageId, romanized: $romanized)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LetterModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
