import 'dart:convert';
import 'dart:io';

/// Fetches thumbnail image URLs from the Wikipedia REST API.
/// Results are cached in-memory so each word is only looked up once per session.
class WordImageService {
  WordImageService._();
  static final WordImageService instance = WordImageService._();

  final Map<String, String?> _cache = {};

  /// Words where the English translation is too generic for a good Wikipedia
  /// image — map them to a more specific search term.
  static const Map<String, String> _searchOverrides = {
    'god': 'Shiva',
    'sage': 'Rishi',
    'avvaiyar': 'Avvaiyar',
    'conch shell': 'Conch',
    'tamil language': 'Tamil language',
  };

  Future<String?> getImageUrl(String englishWord) async {
    final key = englishWord.toLowerCase().trim();
    if (_cache.containsKey(key)) return _cache[key];

    final searchTerm = _searchOverrides[key] ?? key;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final uri = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(searchTerm)}',
      );
      final request = await client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.userAgentHeader, 'BhashaKidsApp/1.0 (educational)')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final url = data['thumbnail']?['source'] as String?;
        _cache[key] = url;
        return url;
      }
    } catch (_) {}

    _cache[key] = null;
    return null;
  }
}
