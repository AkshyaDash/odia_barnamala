import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressState {
  final Set<String> tappedLetters;
  final int stars;
  final bool showCelebration;
  final int tapCount;

  const ProgressState({
    required this.tappedLetters,
    required this.stars,
    required this.showCelebration,
    required this.tapCount,
  });

  ProgressState copyWith({
    Set<String>? tappedLetters,
    int? stars,
    bool? showCelebration,
    int? tapCount,
  }) {
    return ProgressState(
      tappedLetters: tappedLetters ?? this.tappedLetters,
      stars: stars ?? this.stars,
      showCelebration: showCelebration ?? this.showCelebration,
      tapCount: tapCount ?? this.tapCount,
    );
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  ProgressNotifier()
      : super(const ProgressState(
          tappedLetters: {},
          stars: 0,
          showCelebration: false,
          tapCount: 0,
        ));

  void onLetterTapped(String letter) {
    final newTapCount = state.tapCount + 1;
    final newTapped = {...state.tappedLetters, letter};
    final shouldCelebrate = newTapCount % 5 == 0;
    final newStars = shouldCelebrate ? state.stars + 1 : state.stars;

    state = state.copyWith(
      tappedLetters: newTapped,
      tapCount: newTapCount,
      stars: newStars,
      showCelebration: shouldCelebrate,
    );
  }

  void dismissCelebration() {
    state = state.copyWith(showCelebration: false);
  }

  void reset() {
    state = const ProgressState(
      tappedLetters: {},
      stars: 0,
      showCelebration: false,
      tapCount: 0,
    );
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>(
  (ref) => ProgressNotifier(),
);
