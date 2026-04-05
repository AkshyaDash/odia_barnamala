import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odia_barnamala/providers/progress_provider.dart';

void main() {
  group('ProgressNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('starts with zero stars and zero taps', () {
      final state = container.read(progressProvider);
      expect(state.stars, 0);
      expect(state.tapCount, 0);
      expect(state.showCelebration, false);
    });

    test('tapping 5 letters triggers celebration and awards 1 star', () {
      final notifier = container.read(progressProvider.notifier);
      for (var i = 0; i < 4; i++) {
        notifier.onLetterTapped('letter_$i');
        expect(container.read(progressProvider).showCelebration, false);
      }
      notifier.onLetterTapped('letter_4');
      final state = container.read(progressProvider);
      expect(state.stars, 1);
      expect(state.showCelebration, true);
    });

    test('dismissCelebration clears the flag', () {
      final notifier = container.read(progressProvider.notifier);
      for (var i = 0; i < 5; i++) {
        notifier.onLetterTapped('l$i');
      }
      notifier.dismissCelebration();
      expect(container.read(progressProvider).showCelebration, false);
    });

    test('reset clears everything', () {
      final notifier = container.read(progressProvider.notifier);
      for (var i = 0; i < 10; i++) {
        notifier.onLetterTapped('l$i');
      }
      notifier.reset();
      final state = container.read(progressProvider);
      expect(state.stars, 0);
      expect(state.tapCount, 0);
      expect(state.tappedLetters.isEmpty, true);
    });
  });
}
