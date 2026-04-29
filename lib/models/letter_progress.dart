class LetterProgress {
  final int? id;
  final int letterId;
  final int stars;
  final String? learnedAt;
  final int traceCount;

  const LetterProgress({
    this.id,
    required this.letterId,
    required this.stars,
    this.learnedAt,
    required this.traceCount,
  });

  factory LetterProgress.fromMap(Map<String, dynamic> map) {
    return LetterProgress(
      id: map['id'] as int?,
      letterId: map['letter_id'] as int,
      stars: map['stars'] as int,
      learnedAt: map['learned_at'] as String?,
      traceCount: map['trace_count'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'letter_id': letterId,
      'stars': stars,
      'learned_at': learnedAt,
      'trace_count': traceCount,
    };
  }
}
