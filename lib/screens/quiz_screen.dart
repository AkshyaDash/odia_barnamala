import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../data/bhasha_database_helper.dart';
import '../models/language.dart';
import '../models/letter_new.dart';
import '../providers/quiz_provider.dart';
import '../theme/bhasha_design_system.dart';

class QuizScreen extends StatefulWidget {
  final Language language;

  const QuizScreen({super.key, required this.language});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showResult = false;
  int _lastAutoPlayedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuiz(widget.language.id!);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playLetterAudio(Letter letter) async {
    try {
      await _audioPlayer.setAsset(letter.audioFile);
      await _audioPlayer.play();
    } catch (_) {}
  }

  Future<void> _playUiSound(String assetPath) async {
    try {
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (_) {}
  }

  void _onOptionTap(QuizProvider quiz, int index) {
    if (quiz.answered) return;

    final option = quiz.currentOptions[index];
    final isCorrect = option.id == quiz.currentLetter?.id;

    quiz.answerQuestion(index, isCorrect);

    if (isCorrect) {
      _playUiSound('assets/audio/ui/correct.mp3');
    } else {
      _playUiSound('assets/audio/ui/wrong.mp3');
    }

    // Auto-advance after 1200ms
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final q = context.read<QuizProvider>();
      q.nextQuestion();
      if (q.isComplete) {
        // Save result
        DatabaseHelper.instance.saveQuizResult(
          widget.language.id!,
          q.score,
          100,
        );
        setState(() => _showResult = true);
      } else {
        // Auto-play audio for next question
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && q.currentLetter != null) {
            _playLetterAudio(q.currentLetter!);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    if (_showResult) {
      return _QuizResultView(
        score: quiz.score,
        onPlayAgain: () {
          setState(() => _showResult = false);
          quiz.loadQuiz(widget.language.id!);
        },
        onGoHome: () => Navigator.pop(context),
      );
    }

    // Auto-play audio once per question (guard prevents re-firing on every rebuild)
    if (!quiz.answered &&
        quiz.currentLetter != null &&
        quiz.currentIndex != _lastAutoPlayedIndex) {
      _lastAutoPlayedIndex = quiz.currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !quiz.answered && quiz.currentLetter != null) {
            _playLetterAudio(quiz.currentLetter!);
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: BhashaColors.quizLight,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BhashaHeader(
              title: 'Quiz time!',
              subtitle:
                  'Question ${quiz.currentIndex + 1} of ${quiz.quizLetters.length}',
              color: BhashaColors.quiz,
              onBack: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: quiz.quizLetters.isEmpty
                ? const Center(
                    child:
                        CircularProgressIndicator(color: BhashaColors.quiz))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Progress dots
                        _ProgressDots(
                          total: quiz.quizLetters.length,
                          current: quiz.currentIndex,
                        ),
                        const SizedBox(height: 20),
                        // Question card
                        _QuestionCard(
                          letter: quiz.currentLetter,
                          onPlayAudio: () {
                            if (quiz.currentLetter != null) {
                              _playLetterAudio(quiz.currentLetter!);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        // Answer options 2x2
                        _AnswerGrid(
                          options: quiz.currentOptions,
                          correctId: quiz.currentLetter?.id,
                          answered: quiz.answered,
                          selectedIndex: quiz.selectedIndex,
                          onTap: (i) => _onOptionTap(quiz, i),
                        ),
                        const SizedBox(height: 16),
                        // Score row
                        _ScoreRow(score: quiz.score),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress dots
// ---------------------------------------------------------------------------

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;

  const _ProgressDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        Color color;
        if (i < current) {
          color = BhashaColors.quiz;
        } else if (i == current) {
          color = BhashaColors.quizAccent;
        } else {
          color = BhashaColors.quizBorder;
        }
        return Container(
          width: 24,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Question card
// ---------------------------------------------------------------------------

class _QuestionCard extends StatelessWidget {
  final Letter? letter;
  final VoidCallback onPlayAudio;

  const _QuestionCard({required this.letter, required this.onPlayAudio});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BhashaColors.quizBorder, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Tap to hear the sound, then pick the right letter',
            style: BhashaTextStyles.bodySmall.copyWith(
              color: BhashaColors.quiz,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onPlayAudio,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: BhashaColors.quizLight,
                shape: BoxShape.circle,
                border: Border.all(color: BhashaColors.quizAccent, width: 3),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                size: 32,
                color: BhashaColors.quiz,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Answer options grid (2x2)
// ---------------------------------------------------------------------------

class _AnswerGrid extends StatelessWidget {
  final List<Letter> options;
  final int? correctId;
  final bool answered;
  final int? selectedIndex;
  final void Function(int) onTap;

  const _AnswerGrid({
    required this.options,
    required this.correctId,
    required this.answered,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOption(0),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOption(1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: options.length > 2
                  ? _buildOption(2)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: options.length > 3
                  ? _buildOption(3)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOption(int index) {
    if (index >= options.length) return const SizedBox.shrink();

    final option = options[index];
    final isCorrectOption = option.id == correctId;

    bool showCorrect = false;
    bool showWrong = false;

    if (answered) {
      if (isCorrectOption) {
        showCorrect = true;
      } else if (selectedIndex == index) {
        showWrong = true;
      }
    }

    return _AnimatedQuizOption(
      character: option.unicode,
      label: option.romanized,
      isCorrect: showCorrect,
      isWrong: showWrong,
      onTap: () => onTap(index),
    );
  }
}

class _AnimatedQuizOption extends StatefulWidget {
  final String character;
  final String label;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const _AnimatedQuizOption({
    required this.character,
    required this.label,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  @override
  State<_AnimatedQuizOption> createState() => _AnimatedQuizOptionState();
}

class _AnimatedQuizOptionState extends State<_AnimatedQuizOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedQuizOption old) {
    super.didUpdateWidget(old);
    if (widget.isWrong && !old.isWrong) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = QuizOption(
      character: widget.character,
      label: widget.label,
      isCorrect: widget.isCorrect,
      isWrong: widget.isWrong,
      onTap: widget.onTap,
    );

    if (widget.isWrong) {
      child = AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final t = _shakeController.value;
          final offset = sin(t * pi * 6) * 6; // 3 cycles, ±6px
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: child,
      );
    }

    if (widget.isCorrect) {
      child = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.1),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: child,
      );
    }

    return child;
  }
}

// ---------------------------------------------------------------------------
// Score row
// ---------------------------------------------------------------------------

class _ScoreRow extends StatelessWidget {
  final int score;

  const _ScoreRow({required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Score',
          style: BhashaTextStyles.body.copyWith(
            color: BhashaColors.quiz,
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            const Icon(Icons.star_rounded,
                color: Color(0xFFFFB800), size: 22),
            const SizedBox(width: 4),
            Text(
              '$score',
              style: const TextStyle(
                fontFamily: BhashaTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BhashaColors.quiz,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz result screen (inline)
// ---------------------------------------------------------------------------

class _QuizResultView extends StatelessWidget {
  final int score;
  final VoidCallback onPlayAgain;
  final VoidCallback onGoHome;

  const _QuizResultView({
    required this.score,
    required this.onPlayAgain,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    String emoji;
    String message;
    if (score >= 80) {
      emoji = '\u{1F389}'; // 🎉
      message = 'Amazing job!';
    } else if (score >= 60) {
      emoji = '\u{1F60A}'; // 😊
      message = 'Good effort!';
    } else {
      emoji = '\u{1F4AA}'; // 💪
      message = 'Keep practicing!';
    }

    return Scaffold(
      backgroundColor: BhashaColors.quizLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: BhashaTextStyles.screenTitle.copyWith(
                    color: BhashaColors.quiz,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontFamily: BhashaTextStyles.fontFamily,
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    color: BhashaColors.quiz,
                  ),
                ),
                Text(
                  'out of 100',
                  style: BhashaTextStyles.body.copyWith(
                    color: BhashaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BhashaColors.quiz,
                    ),
                    onPressed: onPlayAgain,
                    child: const Text('Play again'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BhashaColors.quiz,
                      side: const BorderSide(color: BhashaColors.quiz),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(BhashaSpacing.radiusMd),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: BhashaSpacing.lg,
                        vertical: BhashaSpacing.md,
                      ),
                    ),
                    onPressed: onGoHome,
                    child: const Text('Go home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
