import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/bhasha_database_helper.dart';
import '../models/letter_new.dart';

class QuizProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Letter> _quizLetters = [];
  List<Letter> get quizLetters => _quizLetters;

  List<Letter> _allLetters = [];

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  int _score = 0;
  int get score => _score;

  bool _answered = false;
  bool get answered => _answered;

  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;

  List<Letter> _currentOptions = [];
  List<Letter> get currentOptions => _currentOptions;

  Letter? get currentLetter =>
      _currentIndex < _quizLetters.length ? _quizLetters[_currentIndex] : null;

  bool get isComplete => _currentIndex >= _quizLetters.length;

  Future<void> loadQuiz(int langId) async {
    _allLetters = await _db.getLettersForLanguage(langId);
    final rng = Random();
    final shuffled = List<Letter>.from(_allLetters)..shuffle(rng);
    _quizLetters = shuffled.take(10).toList();
    _currentIndex = 0;
    _score = 0;
    _answered = false;
    _selectedIndex = null;
    _generateOptions();
    notifyListeners();
  }

  void _generateOptions() {
    if (isComplete) return;
    final correct = _quizLetters[_currentIndex];
    final rng = Random();
    final wrong = _allLetters.where((l) => l.id != correct.id).toList()
      ..shuffle(rng);
    final options = [correct, ...wrong.take(3)];
    options.shuffle(rng);
    _currentOptions = options;
  }

  void answerQuestion(int index, bool isCorrect) {
    if (_answered) return;
    _answered = true;
    _selectedIndex = index;
    if (isCorrect) {
      _score += 10;
    }
    notifyListeners();
  }

  void nextQuestion() {
    _currentIndex++;
    _answered = false;
    _selectedIndex = null;
    _generateOptions();
    notifyListeners();
  }

  void resetQuiz() {
    _quizLetters = [];
    _currentIndex = 0;
    _score = 0;
    _answered = false;
    _selectedIndex = null;
    _currentOptions = [];
    notifyListeners();
  }
}
