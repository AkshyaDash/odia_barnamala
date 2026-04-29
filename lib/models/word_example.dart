class WordExample {
  final int? id;
  final int letterId;
  final String wordScript;
  final String wordRoman;
  final String wordEnglish;
  final String? imagePath;
  final String? audioPath;

  const WordExample({
    this.id,
    required this.letterId,
    required this.wordScript,
    required this.wordRoman,
    required this.wordEnglish,
    this.imagePath,
    this.audioPath,
  });

  factory WordExample.fromMap(Map<String, dynamic> map) {
    return WordExample(
      id: map['id'] as int?,
      letterId: map['letter_id'] as int,
      wordScript: map['word_script'] as String,
      wordRoman: map['word_roman'] as String,
      wordEnglish: map['word_english'] as String,
      imagePath: map['image_path'] as String?,
      audioPath: map['audio_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'letter_id': letterId,
      'word_script': wordScript,
      'word_roman': wordRoman,
      'word_english': wordEnglish,
      'image_path': imagePath,
      'audio_path': audioPath,
    };
  }
}
