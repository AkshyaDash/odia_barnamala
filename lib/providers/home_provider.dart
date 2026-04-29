import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bhasha_database_helper.dart';
import '../models/language.dart';
import '../models/letter_new.dart';
import '../models/streak.dart';

class HomeProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Language? _activeLanguage;
  Language? get activeLanguage => _activeLanguage;

  List<Language> _languages = [];
  List<Language> get languages => _languages;

  Streak? _streak;
  Streak? get streak => _streak;

  Letter? _lastAccessedLetter;
  Letter? get lastAccessedLetter => _lastAccessedLetter;

  Future<void> loadHomeData() async {
    _languages = await _db.getAllLanguages();

    // Restore saved language or default to first (Odia)
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('active_lang_code');

    if (savedCode != null) {
      _activeLanguage = _languages.cast<Language?>().firstWhere(
            (l) => l!.code == savedCode,
            orElse: () => null,
          );
    }
    _activeLanguage ??= _languages.isNotEmpty ? _languages.first : null;

    _streak = await _db.getStreak();
    _lastAccessedLetter = await _db.getLastAccessedLetter();

    notifyListeners();
  }

  Future<void> setActiveLanguage(Language lang) async {
    _activeLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_lang_code', lang.code);
    _lastAccessedLetter = await _db.getLastAccessedLetter();
    notifyListeners();
  }

  Future<void> refreshStreak() async {
    _streak = await _db.getStreak();
    notifyListeners();
  }

  Future<void> refreshLastAccessed() async {
    _lastAccessedLetter = await _db.getLastAccessedLetter();
    notifyListeners();
  }
}
