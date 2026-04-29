class QuizResult {
  final int? id;
  final int langId;
  final int score;
  final int total;
  final String playedAt;

  const QuizResult({
    this.id,
    required this.langId,
    required this.score,
    required this.total,
    required this.playedAt,
  });

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'] as int?,
      langId: map['lang_id'] as int,
      score: map['score'] as int,
      total: map['total'] as int,
      playedAt: map['played_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'lang_id': langId,
      'score': score,
      'total': total,
      'played_at': playedAt,
    };
  }
}
