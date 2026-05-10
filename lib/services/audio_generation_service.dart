import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bhasha_database_helper.dart';
import '../models/language.dart';
import '../models/letter_new.dart';
import '../models/word_example.dart';

/// Result record emitted during [generateForLanguage].
typedef GenerationProgress = ({double progress, String status});

/// Handles on-device audio generation for each language using the
/// Azure Cognitive Services Speech REST API.
///
/// Bundled languages (en, or, hi, ta) have pre-recorded assets in
/// assets/audio/ and are marked complete instantly without any API calls.
///
/// Paid languages call Azure TTS once per letter + word, saving the MP3
/// to local storage. After setup the app is fully offline.
///
/// API key + region are injected at build time via --dart-define:
///   flutter build apk
///     --dart-define=AZURE_SPEECH_KEY=xxx
///     --dart-define=AZURE_SPEECH_REGION=eastasia
class AudioGenerationService {
  AudioGenerationService._();
  static final AudioGenerationService instance = AudioGenerationService._();

  static const _bundledCodes = {'en', 'or', 'hi', 'ta'};

  // Injected at build time. Empty string = not configured (dev warning only).
  static const _apiKey = String.fromEnvironment('AZURE_SPEECH_KEY');
  static const _region =
      String.fromEnvironment('AZURE_SPEECH_REGION', defaultValue: 'eastasia');

  /// Microsoft Neural voice for each language code.
  /// Mirrors the voice choices in generate_audio.py exactly.
  static const Map<String, String> _voices = {
    'en': 'en-US-AriaNeural',
    'or': 'hi-IN-SwaraNeural', // Hindi voice pronounces Odia barnamala identically
    'hi': 'hi-IN-SwaraNeural',
    'ta': 'ta-IN-PallaviNeural',
    'te': 'te-IN-ShrutiNeural',
    'kn': 'kn-IN-SapnaNeural',
    'ml': 'ml-IN-SobhanaNeural',
    'bn': 'bn-IN-TanishaaNeural',
    'gu': 'gu-IN-DhwaniNeural',
    'pa': 'pa-IN-OjasveeNeural',
    'mr': 'mr-IN-AarohiNeural',
    'ur': 'ur-IN-GulNeural',
    'as': 'as-IN-YashicaNeural',
  };

  static const _prefsKey = 'generated_language_codes';

  final _dio = Dio();
  Set<String> _generatedCodes = {};
  String? _docsPath;

  /// Load previously generated language codes from SharedPreferences.
  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _docsPath = dir.path;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw != null) _generatedCodes = raw.toSet();
  }

  /// True if audio for [langCode] has been fully generated and saved.
  /// Bundled languages always return true.
  bool isGenerated(String langCode) =>
      _bundledCodes.contains(langCode) || _generatedCodes.contains(langCode);

  /// Generates audio for all letters and words in [lang].
  ///
  /// For bundled languages emits a single (1.0, 'Audio ready') event.
  /// For paid languages, calls Azure TTS per item and yields progress.
  /// Throws [AudioGenerationException] on unrecoverable network errors.
  Stream<GenerationProgress> generateForLanguage(
    Language lang,
    List<Letter> letters,
    List<WordExample> words,
  ) async* {
    if (_bundledCodes.contains(lang.code)) {
      yield (progress: 1.0, status: 'Audio ready');
      return;
    }

    if (_apiKey.isEmpty) {
      throw const AudioGenerationException(
        'Azure Speech API key not configured. '
        'Build with --dart-define=AZURE_SPEECH_KEY=your_key',
      );
    }

    final audioDir = Directory('$_docsPath/audio/${lang.code}');
    await audioDir.create(recursive: true);

    final total = letters.length + words.length;
    int done = 0;

    // Generate letter audio
    for (final letter in letters) {
      final path = _letterPath(lang.code, letter.id!);
      if (!File(path).existsSync()) {
        final bytes = await _synthesize(letter.unicode, lang.code);
        if (bytes != null) await File(path).writeAsBytes(bytes);
      }
      done++;
      yield (
        progress: done / total,
        status: 'Generating audio… $done/${letters.length} letters',
      );
    }

    // Generate word audio
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.id == null) {
        done++;
        continue;
      }
      final path = _wordPath(lang.code, word.id!);
      if (!File(path).existsSync()) {
        final bytes = await _synthesize(word.wordScript, lang.code);
        if (bytes != null) await File(path).writeAsBytes(bytes);
      }
      done++;
      yield (
        progress: done / total,
        status:
            'Generating audio… ${letters.length}/${letters.length} letters, ${i + 1}/${words.length} words',
      );
    }

    await _markGenerated(lang.code);
    yield (progress: 1.0, status: 'Audio ready');
  }

  /// Returns the local file path for a letter's generated MP3, or null if
  /// the file does not exist (caller should fall back to the bundled asset).
  String? resolveLetterAudioPath(String langCode, int letterId) {
    if (_docsPath == null) return null;
    final path = _letterPath(langCode, letterId);
    return File(path).existsSync() ? path : null;
  }

  /// Returns the local file path for a word's generated MP3, or null if
  /// the file does not exist.
  String? resolveWordAudioPath(String langCode, int wordId) {
    if (_docsPath == null) return null;
    final path = _wordPath(langCode, wordId);
    return File(path).existsSync() ? path : null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _letterPath(String langCode, int letterId) =>
      '$_docsPath/audio/$langCode/letter_$letterId.mp3';

  String _wordPath(String langCode, int wordId) =>
      '$_docsPath/audio/$langCode/word_$wordId.mp3';

  String _ssml(String text, String voice) {
    final lang = voice.substring(0, 5); // e.g. "hi-IN"
    return "<speak version='1.0' xml:lang='$lang'>"
        "<voice name='$voice'>$text</voice>"
        '</speak>';
  }

  Future<Uint8List?> _synthesize(String text, String langCode) async {
    final voice = _voices[langCode] ?? 'en-US-AriaNeural';
    const url =
        'https://$_region.tts.speech.microsoft.com/cognitiveservices/v1';
    try {
      final response = await _dio.post<List<int>>(
        url,
        data: _ssml(text, voice),
        options: Options(
          headers: {
            'Ocp-Apim-Subscription-Key': _apiKey,
            'Content-Type': 'application/ssml+xml',
            'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
            'User-Agent': 'VarnamalaApp',
          },
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final data = response.data;
      return data != null ? Uint8List.fromList(data) : null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const AudioGenerationException('No internet connection.');
      }
      // Non-fatal: log and return null so caller skips this item
      return null;
    }
  }

  Future<void> _markGenerated(String langCode) async {
    _generatedCodes.add(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _generatedCodes.toList());
  }
}

class AudioGenerationException implements Exception {
  final String message;
  const AudioGenerationException(this.message);
  @override
  String toString() => 'AudioGenerationException: $message';
}

/// Convenience: fetch letters + words for a language from the DB,
/// then stream generation progress. Used by the setup screens.
Stream<GenerationProgress> generateAudioForLanguage(Language lang) async* {
  final db = DatabaseHelper.instance;
  final letters = await db.getLettersForLanguage(lang.id!);
  final words = await db.getWordExamplesForLanguage(lang.id!);
  yield* AudioGenerationService.instance
      .generateForLanguage(lang, letters, words);
}
