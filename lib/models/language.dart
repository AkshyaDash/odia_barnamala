class Language {
  final int? id;
  final String code;
  final String name;
  final String script;
  final int totalLetters;

  const Language({
    this.id,
    required this.code,
    required this.name,
    required this.script,
    required this.totalLetters,
  });

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      script: map['script'] as String,
      totalLetters: map['total_letters'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'script': script,
      'total_letters': totalLetters,
    };
  }
}
