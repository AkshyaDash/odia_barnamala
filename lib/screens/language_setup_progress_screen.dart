import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bhasha_database_helper.dart';
import '../models/language.dart';
import '../services/audio_generation_service.dart';
import '../services/image_prefetch_service.dart';
import '../services/language_purchase_service.dart';
import '../theme/bhasha_design_system.dart';

/// Shown after the user taps "Start learning" on the onboarding screen.
/// Generates audio (via Azure TTS) and pre-fetches word images for each
/// selected language, then navigates to the home screen.
class LanguageSetupProgressScreen extends StatefulWidget {
  final List<Language> selectedLanguages;

  const LanguageSetupProgressScreen({
    super.key,
    required this.selectedLanguages,
  });

  @override
  State<LanguageSetupProgressScreen> createState() =>
      _LanguageSetupProgressScreenState();
}

class _LanguageSetupProgressScreenState
    extends State<LanguageSetupProgressScreen> {
  late final Map<String, double> _audioProgress;
  late final Map<String, double> _imageProgress;
  late final Map<String, String> _audioStatus;
  final Map<String, bool> _done = {};
  final Map<String, bool> _audioError = {};

  final _db = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _audioProgress = {for (final l in widget.selectedLanguages) l.code: 0.0};
    _imageProgress = {for (final l in widget.selectedLanguages) l.code: 0.0};
    _audioStatus = {
      for (final l in widget.selectedLanguages) l.code: 'Preparing audio…'
    };
    _runSetup();
  }

  bool get _allDone =>
      widget.selectedLanguages.isNotEmpty &&
      widget.selectedLanguages.every((l) => _done[l.code] == true);

  Future<void> _runSetup() async {
    for (final lang in widget.selectedLanguages) {
      await _generateAudio(lang);
      await _prefetchImages(lang);
      if (mounted) setState(() => _done[lang.code] = true);
    }
    await _finish();
  }

  Future<void> _generateAudio(Language lang) async {
    if (lang.id == null) return;
    try {
      final letters = await _db.getLettersForLanguage(lang.id!);
      final words = await _db.getWordExamplesForLanguage(lang.id!);

      await for (final (:progress, :status) in AudioGenerationService.instance
          .generateForLanguage(lang, letters, words)) {
        if (!mounted) return;
        setState(() {
          _audioProgress[lang.code] = progress;
          _audioStatus[lang.code] = status;
          _audioError[lang.code] = false;
        });
      }
    } on AudioGenerationException {
      if (!mounted) return;
      setState(() => _audioError[lang.code] = true);
      // Wait for user to tap retry — pause here until error is cleared
      await _waitForRetry(lang.code);
      if (mounted) await _generateAudio(lang);
    }
  }

  // Completes when the user taps Retry (clears the error flag).
  Future<void> _waitForRetry(String code) async {
    while (_audioError[code] == true) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> _prefetchImages(Language lang) async {
    if (lang.id == null) return;
    await for (final progress
        in ImagePrefetchService.instance.prefetchForLanguage(lang.id!)) {
      if (!mounted) return;
      setState(() => _imageProgress[lang.code] = progress);
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BhashaColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Setting up your\nlanguages',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: BhashaColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Generating audio and fetching images so the\napp works fully offline.',
                style: TextStyle(
                  fontSize: 14,
                  color: BhashaColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...widget.selectedLanguages.map((l) => _LanguageSetupTile(
                          language: l,
                          audioProgress: _audioProgress[l.code] ?? 0,
                          imageProgress: _imageProgress[l.code] ?? 0,
                          audioStatus: _audioStatus[l.code] ?? '',
                          isDone: _done[l.code] ?? false,
                          hasError: _audioError[l.code] ?? false,
                          isFree: LanguagePurchaseService.freeCodes
                              .contains(l.code),
                          onRetry: () =>
                              setState(() => _audioError[l.code] = false),
                        )),
                    if (_allDone) ...[
                      const SizedBox(height: 28),
                      const Center(
                        child: Text(
                          'All set! 🎉',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFB300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Your languages are ready to learn!',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF9A8060),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSetupTile extends StatelessWidget {
  final Language language;
  final double audioProgress;
  final double imageProgress;
  final String audioStatus;
  final bool isDone;
  final bool hasError;
  final bool isFree;
  final VoidCallback onRetry;

  const _LanguageSetupTile({
    required this.language,
    required this.audioProgress,
    required this.imageProgress,
    required this.audioStatus,
    required this.isDone,
    required this.hasError,
    required this.isFree,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final imageLabel = imageProgress >= 1.0
        ? 'Images cached'
        : imageProgress > 0
            ? 'Fetching images… ${(imageProgress * 100).round()}%'
            : 'Fetching word images…';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BhashaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? Colors.red.shade300
              : isDone
                  ? BhashaColors.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(language.script, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: BhashaColors.textPrimary,
                      ),
                    ),
                    if (isFree)
                      const Text(
                        'Free',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (isDone)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB300),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                )
              else if (hasError)
                const Icon(Icons.error_outline, color: Colors.red, size: 24)
              else
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: BhashaColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasError)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'No internet connection. Please check your connection and try again.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            )
          else ...[
            _ProgressRow(
              label: audioStatus,
              progress: audioProgress,
              done: audioProgress >= 1.0,
            ),
            const SizedBox(height: 8),
            _ProgressRow(
              label: imageLabel,
              progress: imageProgress,
              done: imageProgress >= 1.0,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double progress;
  final bool done;

  const _ProgressRow({
    required this.label,
    required this.progress,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        done
            ? const Icon(Icons.check_circle_rounded,
                size: 14, color: Color(0xFFFFB300))
            : const Icon(Icons.radio_button_unchecked,
                size: 14, color: BhashaColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      done ? BhashaColors.textSecondary : BhashaColors.textPrimary,
                ),
              ),
              if (!done && progress > 0) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor:
                      BhashaColors.primary.withValues(alpha: 0.15),
                  color: BhashaColors.primary,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
