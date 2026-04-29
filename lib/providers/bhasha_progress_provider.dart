import 'package:flutter/foundation.dart';

import '../data/bhasha_database_helper.dart';
import '../models/language.dart';
import '../models/letter_progress.dart';
import '../models/streak.dart';

class ProgressProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Map<int, int> _learnedPerLanguage = {};
  Map<int, int> get learnedPerLanguage => _learnedPerLanguage;

  int _totalLearned = 0;
  int get totalLearned => _totalLearned;

  Streak? _streak;
  Streak? get streak => _streak;

  List<LetterProgress> _recentActivity = [];
  List<LetterProgress> get recentActivity => _recentActivity;

  List<Language> _languages = [];
  List<Language> get languages => _languages;

  int _languagesExplored = 0;
  int get languagesExplored => _languagesExplored;

  Future<void> loadProgress() async {
    _languages = await _db.getAllLanguages();
    _streak = await _db.getStreak();

    final allProgress = await _db.getAllProgress();
    _recentActivity = allProgress.take(5).toList();

    _totalLearned = allProgress.where((p) => p.stars > 0).length;

    _learnedPerLanguage = {};
    _languagesExplored = 0;

    for (final lang in _languages) {
      if (lang.id == null) continue;
      final count = await _db.getLearnedCount(lang.id!);
      _learnedPerLanguage[lang.id!] = count;
      if (count > 0) _languagesExplored++;
    }

    notifyListeners();
  }
}
