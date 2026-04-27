# Bhasha — Indian Language Alphabet App
### Project Plan & Claude Code Context

> This file is the single source of truth for the Bhasha app project.
> Claude Code should read this before making any changes to the codebase.

---

## What this app is

A kids' alphabet learning app covering all **13 languages printed on Indian currency notes**. Children (ages 3–8) learn to recognise, hear, and trace letters in each script. The app works fully offline, requires no account, and has no ads.

**App name:** Bhasha (भाषा) — meaning "language" in Sanskrit/Hindi, recognised across all 13 languages.

---

## The 13 languages

| # | Language | Script family |
|---|----------|---------------|
| 1 | Hindi | Devanagari |
| 2 | English | Latin |
| 3 | Bengali | Bengali |
| 4 | Telugu | Telugu |
| 5 | Marathi | Devanagari |
| 6 | Tamil | Tamil |
| 7 | Kannada | Kannada |
| 8 | Gujarati | Gujarati |
| 9 | Urdu | Perso-Arabic |
| 10 | Malayalam | Malayalam |
| 11 | Odia | Odia (origin of this project) |
| 12 | Punjabi | Gurmukhi |
| 13 | Assamese | Bengali (variant) |

> Sanskrit was on older notes but is excluded from the core 13 for now.

---

## Monetisation model — Option B (locked in)

| Tier | Price | Content |
|------|-------|---------|
| Free forever | ₹0 | English alphabet, full feature set |
| All languages unlock | ₹199 one-time | All 12 remaining languages |

**Rationale:**
- Parents of young children strongly dislike subscription models for kids apps
- ₹199 is an impulse-buy price point (equivalent to a board game or book)
- "Unlock everything once" is a simple, trustworthy message
- No recurring charges = better reviews = better App Store ranking
- International pricing: $3.99 USD / £2.99 GBP / AED 14.99 (set per-region in Play Console / App Store Connect)

**Platform cut:** Google Play and Apple App Store take 15–30%. Net on ₹199 is approximately ₹140–170. Price with this in mind.

---

## Tech stack

| Concern | Choice | Reason |
|---------|--------|--------|
| Framework | Flutter | Single codebase for Android + iOS, excellent Canvas support for tracing |
| Local database | SQLite via `sqflite` | No server needed, offline-first, fast |
| In-app purchase | `in_app_purchase` Flutter package | Works with both Google Play Billing and Apple StoreKit |
| Audio | Bundled `.mp3` assets | Fully offline, no streaming |
| State management | Provider or Riverpod | Keep it simple for a solo/small team |
| Target platform | Android first, iOS after | Play Store launch → App Store after initial traction |

**Constraints:**
- No API server — ever. All data is local.
- No user accounts. No login.
- No ads. Clean experience for children.
- COPPA compliant — no data collection from children.

---

## SQLite schema

```sql
-- Languages available in the app
CREATE TABLE languages (
  id INTEGER PRIMARY KEY,
  code TEXT NOT NULL,           -- e.g. 'odia', 'hindi', 'tamil'
  name_english TEXT NOT NULL,   -- e.g. 'Odia'
  name_native TEXT NOT NULL,    -- e.g. 'ଓଡ଼ିଆ'
  script_family TEXT,           -- e.g. 'Devanagari', 'Tamil'
  is_free INTEGER DEFAULT 0,    -- 1 = free, 0 = requires purchase
  is_unlocked INTEGER DEFAULT 0,-- 1 = user has purchased
  sort_order INTEGER
);

-- Individual letters per language
CREATE TABLE letters (
  id INTEGER PRIMARY KEY,
  language_id INTEGER REFERENCES languages(id),
  unicode_char TEXT NOT NULL,   -- the actual character e.g. 'ଅ'
  transliteration TEXT,         -- Roman approximation e.g. 'a'
  audio_asset_path TEXT,        -- e.g. 'assets/audio/odia/a.mp3'
  stroke_svg_path TEXT,         -- SVG path data for stroke-order animation
  sort_order INTEGER,
  category TEXT                 -- e.g. 'vowel', 'consonant'
);

-- Example words that start with or feature each letter
CREATE TABLE words (
  id INTEGER PRIMARY KEY,
  letter_id INTEGER REFERENCES letters(id),
  word_native TEXT NOT NULL,    -- e.g. 'ଅଙ୍କ'
  word_meaning TEXT,            -- English meaning e.g. 'number'
  image_asset_path TEXT,        -- e.g. 'assets/images/odia/anka.png'
  audio_asset_path TEXT         -- pronunciation of the word
);

-- User progress per letter
CREATE TABLE progress (
  id INTEGER PRIMARY KEY,
  letter_id INTEGER REFERENCES letters(id),
  stars INTEGER DEFAULT 0,      -- 0–3: heard=1, traced=2, quizzed=3
  attempts INTEGER DEFAULT 0,
  last_seen TEXT,               -- ISO date string
  tracing_best_score REAL       -- 0.0–1.0 accuracy
);

-- App-wide settings
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT
);
-- Example rows:
-- ('selected_language', 'odia')
-- ('has_purchased_all', '0')
-- ('daily_letter_date', '2025-01-01')
-- ('daily_letter_id', '42')
-- ('child_name', 'Aarav')
```

---

## Core screens

### 1. Home / language selector
- Grid of 13 language tiles, each showing the language name in its own script + English
- English tile: always unlocked, green border
- Other tiles: show lock icon if not purchased, unlock prompt on tap
- "Unlock all languages — ₹199" banner at bottom when not purchased

### 2. Alphabet grid
- All letters of the selected language in a scrollable grid
- Each cell shows: the character, a star rating (0–3 stars), a coloured dot for category (vowel/consonant)
- Tap a letter → Letter detail screen

### 3. Letter detail
- Large character display (centred, 120px+)
- Play audio button — plays native speaker pronunciation
- Example word with image below the letter
- "Learn to write" button → Tracing screen
- "Quiz me" button → Quiz screen
- Navigation arrows to prev/next letter

### 4. Tracing screen
- Faint grey letter as background guide
- Animated stroke-order preview plays once on entry (dashed line reveals stroke by stroke)
- Child draws on canvas overlay
- Accuracy score calculated (0–100%) based on path similarity
- 3 attempts tracked, best score saved to `progress` table
- Stars awarded: first trace = 1 star, score >60% = 2 stars, score >85% = 3 stars

### 5. Listen & Tap mode
- Audio plays a letter name
- 4–6 letter tiles shown on screen
- Child taps the correct one
- Wrong tap: gentle shake animation, try again
- Correct tap: celebration animation + next letter
- Works for pre-literate children — no reading required

### 6. Mini-games (Phase 3)
- **Match it:** Connect letter to picture
- **Spell tap:** Hear a word, tap letters in order
- **Find it:** "Find all the vowels" in a grid

### 7. Parental dashboard
- Accessible via a "grown-ups" button (requires simple math puzzle to enter, not a password)
- Shows progress per language, stars earned, letters mastered
- No account, no internet, no data leaves the device

---

## Feature: Daily letter
- One letter highlighted each day across the selected language
- Push notification (optional, parent enables): "Today's letter is ଅ — tap to learn!"
- Completing the daily letter awards a bonus star sticker
- Creates the daily habit loop that drives retention

---

## Gamification system
- **Stars per letter:** 0–3 based on heard / traced / quizzed
- **Language completion ring:** Progress circle on language tile (e.g. "18 / 48 letters mastered")
- **Streak counter:** Consecutive days of learning
- **Badges:** "Vowel master", "First 10 letters", "Full alphabet" per language
- All stored locally in SQLite — no server, no leaderboard, no social features (COPPA)

---

## App Store success factors (ASO)

### App title & subtitle
- Title: `Bhasha — Learn Indian Alphabets`
- Subtitle: `Hindi, Tamil, Bengali & 10 more`

### Keywords to target (Play Store / App Store)
```
hindi alphabet kids, tamil letters learn, bengali barnamala,
odia barnamala, kannada alphabet, gujarati akshar, telugu varnamala,
indian language kids app, learn indian scripts, multilingual kids india,
NRI kids language, heritage language app
```

### Screenshots strategy
- Create one screenshot set per major language (Hindi, Tamil, Bengali, Telugu)
- Show the letter grid, tracing screen, and listen-tap mode
- Use the script characters prominently — parents recognise their own language instantly

### Ratings strategy
- Prompt for a rating after a child earns their first 10 stars (happy moment)
- Never ask during or after a failed attempt
- Respond to every Play Store review in the first month

---

## Build phases

### Phase 1 — Foundation (Weeks 1–3)
Improve the existing Odia app to the quality standard before scaling.

- [ ] Audit existing Odia code, fix any issues
- [ ] Implement SQLite schema above
- [ ] Migrate existing letter data into SQLite
- [ ] Upgrade tracing screen with stroke-order animation
- [ ] Add example word + image to each letter
- [ ] Add "Listen & Tap" mode
- [ ] Implement 3-star progress system
- [ ] Test thoroughly on a physical Android device

### Phase 2 — Multi-language (Weeks 4–7)
- [ ] Build language home screen (13 tiles)
- [ ] Create content pipeline: JSON → SQLite seed for each language
- [ ] Source and bundle audio assets (native speaker recordings per letter)
- [ ] Implement freemium gate (English free, others locked)
- [ ] Integrate `in_app_purchase` Flutter package
- [ ] Test purchase flow end-to-end on Play Store internal testing track
- [ ] Ensure fully offline — no network calls at runtime

### Phase 3 — Engagement & Launch (Weeks 8–11)
- [ ] Daily letter feature + optional push notification
- [ ] Mini-games (match, spell-tap, find-it)
- [ ] Parental dashboard
- [ ] App icon design (script-forward, colourful, recognisable)
- [ ] ASO metadata: titles, descriptions, keywords per language
- [ ] Screenshot sets for Play Store listing
- [ ] Privacy policy page (required for Play Store, COPPA)
- [ ] Submit to Google Play — soft launch India, UK, UAE

### Phase 4 — Growth (Post-launch)
- [ ] iOS build + Apple App Store submission
- [ ] International pricing: USD, GBP, AED
- [ ] NRI community marketing (Indian diaspora Facebook groups, WhatsApp communities)
- [ ] Teacher/classroom mode (bulk unlock for schools)
- [ ] Review prompt system
- [ ] Analytics (privacy-safe, no PII — just crash reports via Firebase Crashlytics)

---

## Content sourcing notes

- **Audio:** Record native speakers for each language (family, community, Fiverr). One clean recording per letter + one per example word. Format: `.mp3`, 44.1kHz, mono, normalised to -16 LUFS.
- **Images:** Commission a single illustrator for all example word images so the visual style is consistent across all 13 languages. Aim for ~300 images total (roughly 20–25 per language average).
- **Stroke order data:** SVG path data for stroke order exists for Devanagari and some scripts in open-source projects. For less-documented scripts (Odia, Assamese), you may need to create these manually or commission them.

---

## What Claude Code should know

When working in this repo:

1. **Do not add any network calls.** The app must work fully offline.
2. **All new screens must follow the existing Flutter widget structure** — check `lib/screens/` for conventions.
3. **All letter/language data goes through SQLite** — never hardcode content in Dart files.
4. **The tracing canvas** is the most technically sensitive part of the app — test on a real device, not just the emulator.
5. **In-app purchase logic** must handle: not purchased, purchase pending, purchase restored, and purchase failed states gracefully.
6. **Target Android SDK:** minSdk 21, targetSdk 34.
7. **The free language is English** (`code = 'english'`, `is_free = 1` in the `languages` table). All others require purchase.

---

## Open questions to resolve

- [ ] Who is recording the audio? (Family member, professional, Fiverr?)
- [ ] Who is designing the app icon and example word illustrations?
- [ ] Do we want Sanskrit as a 14th language in a future update?
- [ ] Should Marathi and Hindi share Devanagari letter data, or be kept separate? (They share the script but not all letters/sounds)
- [ ] Play Store developer account set up? ($25 one-time registration fee)
- [ ] Apple Developer account? ($99/year — do after Android launch)

---

*Last updated: April 2026*
*Plan agreed between project owner and Claude*
