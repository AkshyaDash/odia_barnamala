class Letter {
  final int? id;
  final int langId;
  final String unicode;
  final String romanized;
  final String audioFile;
  final int sortOrder;

  const Letter({
    this.id,
    required this.langId,
    required this.unicode,
    required this.romanized,
    required this.audioFile,
    required this.sortOrder,
  });

  factory Letter.fromMap(Map<String, dynamic> map) {
    return Letter(
      id: map['id'] as int?,
      langId: map['lang_id'] as int,
      unicode: map['unicode'] as String,
      romanized: map['romanized'] as String,
      audioFile: map['audio_file'] as String,
      sortOrder: map['sort_order'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'lang_id': langId,
      'unicode': unicode,
      'romanized': romanized,
      'audio_file': audioFile,
      'sort_order': sortOrder,
    };
  }
}
