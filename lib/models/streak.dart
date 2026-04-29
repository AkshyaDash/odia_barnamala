class Streak {
  final int? id;
  final String lastDate;
  final int current;
  final int longest;

  const Streak({
    this.id,
    required this.lastDate,
    required this.current,
    required this.longest,
  });

  factory Streak.fromMap(Map<String, dynamic> map) {
    return Streak(
      id: map['id'] as int?,
      lastDate: map['last_date'] as String,
      current: map['current'] as int,
      longest: map['longest'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'last_date': lastDate,
      'current': current,
      'longest': longest,
    };
  }
}
