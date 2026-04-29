# Add Language Guide — Bhasha Kids App

This file is Claude's implementation guide. When the user says **"add [Language] language features"**, follow every step in this document — no step is optional unless explicitly marked.

---

## Overview of the Architecture

The app is a Flutter/Dart kids' alphabet learning app using:
- **SQLite** (`bhasha_kids.db`) via `sqflite` — single source of truth for all language content
- **Provider** for state management (`HomeProvider`, `QuizProvider`)
- **AudioPlayers** / `just_audio` for audio playback
- **Assets** declared in `pubspec.yaml` under `assets:` and `fonts:`

Language content lives entirely in the database. The UI reads it dynamically — no screen code changes are needed to support a new language.

---

## Files You Will Edit

| File | What changes |
|------|-------------|
| [lib/data/bhasha_database_helper.dart](../lib/data/bhasha_database_helper.dart) | Letter definitions constant + seeding logic |
| [lib/theme/bhasha_design_system.dart](../lib/theme/bhasha_design_system.dart) | Language card background color |
| [pubspec.yaml](../pubspec.yaml) | New font family (only if script needs bundled font) |
| [lib/data/letter_trace_paths.dart](../lib/data/letter_trace_paths.dart) | Stroke paths (only if tracing is implemented) |

---

## Step 1 — Gather Language Data

Before writing a single line of code, collect or confirm:

### 1a. Letters list
Decide the canonical alphabet for the language. For each letter you need:

```
{
  'unicode': '<script character>',   // the actual character, e.g. 'A' or 'अ'
  'romanized': '<transliteration>',  // e.g. 'A', 'Ka', 'Sha'
  'audio': '<filename>.mp3',         // matches a file in assets/audio/
}
```

**Naming convention for audio files** (must follow exactly):
```
assets/audio/{type}_{name}.mp3
  type  = 'vowel' | 'consonant' | 'letter'   (use 'letter' for scripts like Latin)
  name  = lowercase romanization, no spaces    e.g. 'a', 'ka', 'sha'
  
  Disambiguation: if two letters share a romanization, append a number:
    consonant_ta.mp3 / consonant_ta2.mp3
```

**Vowel count matters**: `getVowelsForLanguage()` in the DB helper uses `sort_order <= 16` to separate vowels from consonants. If your language has a different vowel count, note it — you may need to update that query or pass the vowel boundary explicitly.

### 1b. Word examples
For each letter (or at minimum each vowel), collect 1–2 example words:
```
{
  'script': '<word in the script>',
  'roman': '<romanized word>',
  'english': '<English meaning>',
}
```

### 1c. Font
- **Latin / Roman scripts** (English, French, etc.): No new font needed. System fonts cover these.
- **Indic / CJK / other scripts**: Download the appropriate Noto font (e.g., `NotoSansDevanagari-Regular.ttf` for Hindi). Place it in `assets/fonts/`.

### 1d. Language color
Pick a background color for the language card from `BhashaColors`. See existing constants: `langOdia`, `langHindi`, `langTamil`, etc. Choose one that isn't already used or add a new one.

### 1e. Language metadata
```
code:          ISO 639-1 or ISO 639-2 code  e.g. 'en', 'hi', 'ta', 'bn'
name:          Display name                  e.g. 'English', 'Hindi'
script:        A single representative char  e.g. 'A', 'अ', 'த'
total_letters: Total count of letters        e.g. 26 for English
```

---

## Step 2 — Generate Audio Files

Audio is generated via [`generate_audio.py`](../generate_audio.py) using Microsoft's `edge-tts` library (free, no API key).

### 2a. Pick an edge-tts voice for the language

Browse available voices:
```bash
python -m edge_tts --list-voices
```

Good defaults by script family:
| Script | Voice |
|--------|-------|
| Latin (English, French, Spanish…) | `en-US-AriaNeural` |
| Devanagari (Hindi, Marathi…) | `hi-IN-SwaraNeural` |
| Tamil | `ta-IN-PallaviNeural` |
| Telugu | `te-IN-ShrutiNeural` |
| Bengali / Assamese | `bn-IN-TanishaaNeural` |
| Kannada | `kn-IN-SapnaNeural` |
| Malayalam | `ml-IN-SobhanaNeural` |
| Gujarati | `gu-IN-DhwaniNeural` |
| Punjabi (Gurmukhi) | `pa-IN-OjaswallNeural` |
| Urdu | `ur-IN-GulNeural` |

### 2b. Add entries to `generate_audio.py`

Open [`generate_audio.py`](../generate_audio.py) and append a new block after the English section, following the exact same pattern:

```python
# ---------------------------------------------------------------------------
# [Language] — <voice-name>
# ---------------------------------------------------------------------------
_[LANG]_VOICE = "<voice-name>"
_[LANG]_MAP = {
    # filename stem : text to speak
    "letter_xx": "xx",   # replace with actual filenames and text
}

AUDIO_ENTRIES += [(name, text, _[LANG]_VOICE) for name, text in _[LANG]_MAP.items()]
```

**Naming convention** (must match what you put in `_[lang]LetterDefs`):
```
letter_{name}.mp3          — Latin scripts (English, etc.)
vowel_{name}.mp3           — vowels for Indic scripts
consonant_{name}.mp3       — consonants for Indic scripts
```

For the **text to speak**, pass the actual script character (e.g. `'த'` for Tamil), not the romanization. The TTS voice will pronounce it correctly in the target language.

### 2c. Run the script

```bash
python generate_audio.py
```

The script skips files that already exist, so re-running is safe and won't overwrite Odia or English files.

**Requirements** (first time only):
```bash
python -m pip install edge-tts
```

Files are written to `assets/audio/` automatically. No `pubspec.yaml` change is needed — the whole folder is already declared.

---

## Step 3 — Add Font (if needed)

**Skip this step for Latin-script languages (English, Spanish, French, etc.).**

1. Place the `.ttf` file in `assets/fonts/`
2. Open [pubspec.yaml](../pubspec.yaml) and add the font family under `fonts:`:

```yaml
fonts:
  - family: NotoSansOriya          # existing
    fonts:
      - asset: assets/fonts/NotoSansOriya-Regular.ttf
  - family: NotoSansDevanagari     # NEW — replace with actual family name
    fonts:
      - asset: assets/fonts/NotoSansDevanagari-Regular.ttf
```

3. In [lib/theme/bhasha_design_system.dart](../lib/theme/bhasha_design_system.dart), update `letterChar` and `letterHero` text styles to use a conditional font, OR leave them as-is if you want the system to fall back automatically.

> The current `letterChar` style uses `fontFamily: 'NotoSansOriya'`. For a second language that isn't Odia, the system Noto fonts provide automatic fallback for most scripts. Only bundle a font if the target script fails to render on test devices.

---

## Step 4 — Add Language Color to Design System

Open [lib/theme/bhasha_design_system.dart](../lib/theme/bhasha_design_system.dart) and add a color constant inside `BhashaColors`:

```dart
// Language card backgrounds
static const Color langOdia     = Color(0xFFFFF0E6);  // existing
static const Color langHindi    = Color(0xFFFFF0F5);  // existing
// ... existing colors ...
static const Color langEnglish  = Color(0xFFE6F0FF);  // ADD THIS (example color)
```

Choose a pastel hex that is visually distinct from existing language colors.

---

## Step 5 — Add Letter Definitions to Database Helper

Open [lib/data/bhasha_database_helper.dart](../lib/data/bhasha_database_helper.dart).

### 5a. Add the letter definitions constant

Below the existing `_odiaLetterDefs` constant (around line 438), add a new constant for your language following the exact same structure:

```dart
// ---------------------------------------------------------------------------
// [Language] letter definitions
// ---------------------------------------------------------------------------
static const List<Map<String, String>> _englishLetterDefs = [
  // Vowels first (sort_order 1 to N_VOWELS)
  {'unicode': 'A', 'romanized': 'A', 'audio': 'letter_a.mp3'},
  {'unicode': 'E', 'romanized': 'E', 'audio': 'letter_e.mp3'},
  {'unicode': 'I', 'romanized': 'I', 'audio': 'letter_i.mp3'},
  {'unicode': 'O', 'romanized': 'O', 'audio': 'letter_o.mp3'},
  {'unicode': 'U', 'romanized': 'U', 'audio': 'letter_u.mp3'},
  // Consonants next (sort_order N_VOWELS+1 to total)
  {'unicode': 'B', 'romanized': 'B', 'audio': 'letter_b.mp3'},
  {'unicode': 'C', 'romanized': 'C', 'audio': 'letter_c.mp3'},
  // ... all consonants in standard order ...
  {'unicode': 'Z', 'romanized': 'Z', 'audio': 'letter_z.mp3'},
];
```

**Important ordering rule**: Vowels MUST come first in the list (lower `sort_order` numbers). The grid screen uses `sort_order <= 16` to separate the vowel section header. Adjust the boundary or list order to match your language's vowel/consonant split.

### 5b. Fix the idempotency guard in `seedDatabase()`

**Critical**: The current seeder returns immediately if ANY language exists. This will prevent the second language from being seeded. Change the guard:

**Current code (lines 306–307):**
```dart
final existing = await db.query('languages', limit: 1);
if (existing.isNotEmpty) return;
```

**Replace with per-language checks:**
```dart
// Seed Odia if not already present
final odiaExists = await db.query('languages',
    where: 'code = ?', whereArgs: ['or'], limit: 1);
if (odiaExists.isEmpty) {
  await _seedOdia(db);
}

// Seed [Language] if not already present
final [lang]Exists = await db.query('languages',
    where: 'code = ?', whereArgs: ['[code]'], limit: 1);
if ([lang]Exists.isEmpty) {
  await _seed[Language](db);
}

// Seed streak row if missing
final streakExists = await db.query('streak', limit: 1);
if (streakExists.isEmpty) {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  await db.insert('streak', {
    'last_date': today,
    'current': 0,
    'longest': 0,
  });
}
```

Then extract the existing Odia seeding into a `_seedOdia(Database db)` private method, and create a parallel `_seed[Language](Database db)` method.

### 5c. Create the private seeding method for the new language

```dart
Future<void> _seedEnglish(Database db) async {
  final langId = await db.insert('languages', {
    'code': 'en',
    'name': 'English',
    'script': 'A',
    'total_letters': 26,
  });

  const letters = _englishLetterDefs;
  for (int i = 0; i < letters.length; i++) {
    final def = letters[i];
    await db.insert('letters', {
      'lang_id': langId,
      'unicode': def['unicode'],
      'romanized': def['romanized'],
      'audio_file': 'assets/audio/${def['audio']}',
      'sort_order': i + 1,
    });
  }

  await _seedEnglishWordExamples(db);
}
```

### 5d. Create the word examples seeding method

Follow the exact same pattern as `_seedWordExamples()`:

```dart
Future<void> _seedEnglishWordExamples(Database db) async {
  final letters = await db.query('letters',
      where: "lang_id = (SELECT id FROM languages WHERE code = 'en')",
      orderBy: 'sort_order');

  final wordData = <String, List<Map<String, String>>>{
    'A': [
      {'script': 'Apple',  'roman': 'Apple',  'english': 'A fruit'},
      {'script': 'Ant',    'roman': 'Ant',    'english': 'An insect'},
    ],
    'B': [
      {'script': 'Ball',   'roman': 'Ball',   'english': 'A round toy'},
      {'script': 'Banana', 'roman': 'Banana', 'english': 'A fruit'},
    ],
    // ... one entry per letter minimum, 2 for vowels ...
  };

  for (final letter in letters) {
    final unicode = letter['unicode'] as String;
    final words = wordData[unicode];
    if (words == null) continue;

    for (final word in words) {
      await db.insert('word_examples', {
        'letter_id': letter['id'],
        'word_script': word['script'],
        'word_roman': word['roman'],
        'word_english': word['english'],
        'image_path': null,
        'audio_path': null,
      });
    }
  }
}
```

---

## Step 6 — Add Letter Trace Paths (optional)

**Skip if tracing is not being implemented for this language.**

Open [lib/data/letter_trace_paths.dart](../lib/data/letter_trace_paths.dart).

Each letter's strokes are a `List<List<Offset>>` where:
- Outer list = strokes (lift-pen boundaries)
- Inner list = control points in **normalized [0.0, 1.0] coordinates** (scaled to canvas at render time)
- Interpolation uses **Catmull-Rom splines** for smooth curves

```dart
// Example: letter 'A' with two strokes
static final List<List<Offset>> _pathEnglishA = [
  // Stroke 1: left diagonal
  [Offset(0.5, 0.1), Offset(0.2, 0.9)],
  // Stroke 2: right diagonal
  [Offset(0.5, 0.1), Offset(0.8, 0.9)],
  // Stroke 3: crossbar
  [Offset(0.3, 0.55), Offset(0.7, 0.55)],
];
```

Add a `getEnglishTracePaths(String unicode)` function that returns the path for any given character, paralleling the existing `getTracePaths(unicode)` for Odia.

---

## Step 7 — Verify Database Version

Open [lib/data/bhasha_database_helper.dart](../lib/data/bhasha_database_helper.dart) line 13:

```dart
static const _databaseVersion = 1;
```

If the app has been installed on a real device before with `version: 1`, the `_onCreate` callback will NOT run again for existing installs. The new language seeding runs from `seedDatabase()` (called at startup), not from `_onCreate`, so this is fine — **no migration needed** for adding a language.

Only increment `_databaseVersion` if you are changing the database SCHEMA (adding/removing columns or tables).

---

## Step 8 — Update the Home Screen Language Card Color

Open [lib/screens/bhasha_home_screen.dart](../lib/screens/bhasha_home_screen.dart) and find where language cards are rendered. The card color is looked up by language code. Add the new language's color to the switch/map:

```dart
Color _langColor(String code) {
  return switch (code) {
    'or' => BhashaColors.langOdia,
    'hi' => BhashaColors.langHindi,
    'en' => BhashaColors.langEnglish,  // ADD THIS
    _    => BhashaColors.langOdia,     // fallback
  };
}
```

(If the lookup is implemented differently in the actual file, follow the existing pattern.)

---

## Step 9 — Run and Verify

```bash
flutter run
```

Check each of the following manually:

- [ ] Home screen shows the new language card
- [ ] Tapping the language navigates to Letter Grid with all letters displayed
- [ ] Tapping a letter plays its audio
- [ ] Tapping a letter navigates to the Trace screen (if tracing is enabled)
- [ ] Quiz screen presents letters from the new language
- [ ] Word Examples screen shows correct example words
- [ ] Progress screen counts and displays progress for the new language
- [ ] Existing Odia functionality is unaffected

---

## Common Mistakes to Avoid

1. **Forgetting to fix the idempotency guard** — the second language will never be seeded if `if (existing.isNotEmpty) return` is left unchanged.
2. **Audio file path prefix** — audio is stored as `assets/audio/filename.mp3` in the DB (with the prefix), not just `filename.mp3`.
3. **Vowel sort_order boundary** — `getVowelsForLanguage()` hardcodes `sort_order <= 16`. If your language has fewer or more vowels at the start of the list, this query returns the wrong subset. Either reorder letters so vowels fill `sort_order` 1–N (where N ≤ 16) or update the query.
4. **Missing pubspec font declaration** — adding a `.ttf` to `assets/fonts/` is not enough; it must also be declared under `fonts:` in `pubspec.yaml` with the correct `family` name, otherwise `fontFamily:` references will silently fall back.
5. **Audio files not in pubspec** — the whole `assets/audio/` folder is already declared; individual file entries are not needed.
6. **Database already initialized** — on a dev device, the database already exists. To re-seed from scratch during development, either uninstall the app or call `resetAllProgress()` + delete the languages table, then restart.

---

## Full English Alphabet Reference

For convenience when implementing English:

**Vowels (5):** A, E, I, O, U  
**Consonants (21):** B, C, D, F, G, H, J, K, L, M, N, P, Q, R, S, T, V, W, X, Y, Z

ISO code: `en` | Script char: `A` | Total letters: 26

Audio file naming for English:
```
letter_a.mp3, letter_b.mp3, letter_c.mp3, ..., letter_z.mp3
```

---

## Template: Minimal Letter Definitions Block

Copy this and fill in for any language:

```dart
static const List<Map<String, String>> _[lang]LetterDefs = [
  // Vowels
  {'unicode': '',  'romanized': '',  'audio': 'vowel_.mp3'},
  // Consonants
  {'unicode': '',  'romanized': '',  'audio': 'consonant_.mp3'},
];
```

```dart
Future<void> _seed[Language](Database db) async {
  final langId = await db.insert('languages', {
    'code': '',           // ISO code
    'name': '',           // Display name
    'script': '',         // Single representative character
    'total_letters': 0,   // Replace with actual count
  });
  const letters = _[lang]LetterDefs;
  for (int i = 0; i < letters.length; i++) {
    final def = letters[i];
    await db.insert('letters', {
      'lang_id': langId,
      'unicode':    def['unicode'],
      'romanized':  def['romanized'],
      'audio_file': 'assets/audio/${def['audio']}',
      'sort_order': i + 1,
    });
  }
  await _seed[Language]WordExamples(db);
}
```
