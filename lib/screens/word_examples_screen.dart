import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bhasha_database_helper.dart';
import '../models/language.dart';
import '../models/letter_new.dart';
import '../models/word_example.dart';
import '../theme/bhasha_design_system.dart';

class WordExamplesScreen extends StatefulWidget {
  final Language language;

  const WordExamplesScreen({super.key, required this.language});

  @override
  State<WordExamplesScreen> createState() => _WordExamplesScreenState();
}

class _WordExamplesScreenState extends State<WordExamplesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _pageController = PageController();

  List<Letter> _letters = [];
  final Map<int, List<WordExample>> _wordMap = {};
  int _currentPage = 0;
  bool _loading = true;

  static const _emerald = Color(0xFF059669);
  static const _emeraldLight = Color(0xFF6EE7B7);
  @override
  void initState() {
    super.initState();
    _loadData();
    _incrementVisitCount();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _letters = await _db.getLettersForLanguage(widget.language.id!);
    for (final letter in _letters) {
      if (letter.id != null) {
        _wordMap[letter.id!] = await _db.getWordExamples(letter.id!);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _incrementVisitCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('word_visits') ?? 0;
    await prefs.setInt('word_visits', count + 1);
  }

  Future<void> _playLetterAudio(Letter letter) async {
    try {
      await _audioPlayer.setAsset(letter.audioFile);
      await _audioPlayer.play();
    } catch (_) {}
  }

  Future<void> _playWordAudio(WordExample word) async {
    if (word.audioPath == null) return;
    try {
      await _audioPlayer.setAsset(word.audioPath!);
      await _audioPlayer.play();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BhashaColors.scaffold,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BhashaHeader(
              title: 'Word pictures',
              subtitle: widget.language.name,
              color: _emerald,
              onBack: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)))
                : _letters.isEmpty
                    ? const Center(child: Text('No letters found'))
                    : Column(
                        children: [
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _letters.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentPage = i),
                              itemBuilder: (context, index) {
                                final letter = _letters[index];
                                final words =
                                    _wordMap[letter.id] ?? [];
                                return _LetterWordsPage(
                                  letter: letter,
                                  words: words,
                                  onPlayLetter: () =>
                                      _playLetterAudio(letter),
                                  onPlayWord: _playWordAudio,
                                  langCode: widget.language.code,
                                );
                              },
                            ),
                          ),
                          // Page indicator
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _letters.length.clamp(0, 20),
                                    (i) {
                                      // Show subset of dots
                                      final dotIndex = _letters.length <= 20
                                          ? i
                                          : (_currentPage ~/ 20) * 20 + i;
                                      if (dotIndex >= _letters.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: dotIndex == _currentPage
                                              ? _emerald
                                              : _emeraldLight.withValues(alpha: 0.4),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Letter ${_currentPage + 1} of ${_letters.length}',
                                  style: BhashaTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          // Navigation arrows
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _currentPage > 0
                                      ? () => _pageController.previousPage(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          )
                                      : null,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  color: _emerald,
                                  iconSize: 32,
                                ),
                                const SizedBox(width: 32),
                                IconButton(
                                  onPressed:
                                      _currentPage < _letters.length - 1
                                          ? () =>
                                              _pageController.nextPage(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              )
                                          : null,
                                  icon:
                                      const Icon(Icons.arrow_forward_rounded),
                                  color: _emerald,
                                  iconSize: 32,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-letter word examples page
// ---------------------------------------------------------------------------

class _LetterWordsPage extends StatelessWidget {
  final Letter letter;
  final List<WordExample> words;
  final VoidCallback onPlayLetter;
  final void Function(WordExample) onPlayWord;
  final String langCode;

  const _LetterWordsPage({
    required this.letter,
    required this.words,
    required this.onPlayLetter,
    required this.onPlayWord,
    required this.langCode,
  });

  static const _emerald = Color(0xFF059669);
  static const _emeraldLight = Color(0xFF6EE7B7);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Letter hero
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _emeraldLight, width: 3),
            ),
            child: Center(
              child: Text(
                letter.unicode,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Play button
          GestureDetector(
            onTap: onPlayLetter,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _emerald,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Words starting with ${letter.unicode}',
            style: BhashaTextStyles.body.copyWith(
              color: BhashaColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Word cards
          if (words.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No word examples yet',
                style: BhashaTextStyles.bodySmall.copyWith(
                  color: BhashaColors.textHint,
                ),
              ),
            ),
          ...words.map((word) => _WordCard(
                word: word,
                onPlay: () => onPlayWord(word),
                langCode: langCode,
                letterUnicode: letter.unicode,
                wordIndex: words.indexOf(word),
              )),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final WordExample word;
  final VoidCallback onPlay;
  final String langCode;
  final String letterUnicode;
  final int wordIndex;

  const _WordCard({
    required this.word,
    required this.onPlay,
    required this.langCode,
    required this.letterUnicode,
    required this.wordIndex,
  });

  static const _emeraldLight = Color(0xFF6EE7B7);
  static const _emerald = Color(0xFF059669);
  static const _emeraldBg = Color(0xFFF0FFF4);

  @override
  Widget build(BuildContext context) {
    final imagePath = word.imagePath ??
        'assets/images/word_examples/${langCode}_${letterUnicode}_$wordIndex.png';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _emeraldLight, width: 1.5),
      ),
      child: Row(
        children: [
          // Image or fallback
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _emeraldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    word.wordScript,
                    style: const TextStyle(fontSize: 48),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.wordScript,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  word.wordRoman,
                  style: BhashaTextStyles.bodySmall.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  word.wordEnglish,
                  style: const TextStyle(
                    fontFamily: BhashaTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _emerald,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onPlay,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded,
                          color: _emerald, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Hear it',
                        style: TextStyle(
                          fontFamily: BhashaTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _emerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
