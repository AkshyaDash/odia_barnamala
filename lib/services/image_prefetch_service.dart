import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../data/bhasha_database_helper.dart';
import 'word_image_service.dart';

/// Pre-fetches Wikipedia thumbnail URLs for every word in a language and
/// persists them to the SQLite word_examples.image_path column.
/// Also warms the flutter_cache_manager disk cache so images load offline.
class ImagePrefetchService {
  ImagePrefetchService._();
  static final ImagePrefetchService instance = ImagePrefetchService._();

  /// Yields progress 0.0→1.0 as each word's image is resolved.
  /// Words that already have an image_path in the DB are skipped.
  Stream<double> prefetchForLanguage(int langId) async* {
    final words =
        await DatabaseHelper.instance.getWordExamplesForLanguage(langId);

    if (words.isEmpty) {
      yield 1.0;
      return;
    }

    final pending = words.where((w) => w.imagePath == null).toList();
    if (pending.isEmpty) {
      yield 1.0;
      return;
    }

    int done = 0;
    for (final word in pending) {
      final url =
          await WordImageService.instance.getImageUrl(word.wordEnglish);
      if (url != null && word.id != null) {
        await DatabaseHelper.instance.updateWordImagePath(word.id!, url);
        // Warm the disk cache so the image is available offline.
        try {
          await DefaultCacheManager().downloadFile(url);
        } catch (_) {
          // Non-fatal — image just won't be available fully offline.
        }
      }
      done++;
      yield done / pending.length;
    }
  }
}
