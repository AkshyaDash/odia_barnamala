#!/usr/bin/env python3
"""
Generate audio files for Bhasha Kids app using edge-tts.

Odia:    hi-IN-SwaraNeural  — Hindi voice pronounces barnamala identically.
English: en-US-AriaNeural   — Natural female US-English voice.

Requirements:
    pip install edge-tts

Run from the project root:
    python generate_audio.py
"""

import asyncio
import os
import edge_tts

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "assets", "audio")

# Each entry: (filename_stem, text_to_speak, voice)
AUDIO_ENTRIES = []

# ---------------------------------------------------------------------------
# Odia — hi-IN-SwaraNeural
# ---------------------------------------------------------------------------
_ODIA_VOICE = "hi-IN-SwaraNeural"
_ODIA_MAP = {
    # Vowels
    "vowel_a":   "अ",
    "vowel_aa":  "आ",
    "vowel_i":   "इ",
    "vowel_ii":  "ई",
    "vowel_u":   "उ",
    "vowel_uu":  "ऊ",
    "vowel_ru":  "ऋ",
    "vowel_e":   "ए",
    "vowel_ai":  "ऐ",
    "vowel_o":   "ओ",
    "vowel_au":  "औ",
    "vowel_am":  "अं",
    "vowel_ah":  "अः",

    # Consonants
    "consonant_ka":   "क",
    "consonant_kha":  "ख",
    "consonant_ga":   "ग",
    "consonant_gha":  "घ",
    "consonant_nga":  "ङ",
    "consonant_cha":  "च",
    "consonant_chha": "छ",
    "consonant_ja":   "ज",
    "consonant_jha":  "झ",
    "consonant_nya":  "ञ",
    "consonant_ta":   "ट",
    "consonant_tha":  "ठ",
    "consonant_da":   "ड",
    "consonant_dha":  "ढ",
    "consonant_na":   "ण",
    "consonant_ta2":  "त",
    "consonant_tha2": "थ",
    "consonant_da2":  "द",
    "consonant_dha2": "ध",
    "consonant_na2":  "न",
    "consonant_pa":   "प",
    "consonant_pha":  "फ",
    "consonant_ba":   "ब",
    "consonant_bha":  "भ",
    "consonant_ma":   "म",
    "consonant_ya":   "य",
    "consonant_ra":   "र",
    "consonant_la":   "ल",
    "consonant_va":   "व",
    "consonant_sha":  "श",
    "consonant_ssa":  "ष",
    "consonant_sa":   "स",
    "consonant_ha":   "ह",
    "consonant_lla":  "ळ",
    "consonant_ksha": "क्ष",
    "consonant_gya":  "ज्ञ",
}

AUDIO_ENTRIES += [(name, text, _ODIA_VOICE) for name, text in _ODIA_MAP.items()]

# ---------------------------------------------------------------------------
# English — en-US-AriaNeural
# ---------------------------------------------------------------------------
_EN_VOICE = "en-US-AriaNeural"
_EN_MAP = {
    "letter_a": "A",
    "letter_b": "B",
    "letter_c": "C",
    "letter_d": "D",
    "letter_e": "E",
    "letter_f": "F",
    "letter_g": "G",
    "letter_h": "H",
    "letter_i": "I",
    "letter_j": "J",
    "letter_k": "K",
    "letter_l": "L",
    "letter_m": "M",
    "letter_n": "N",
    "letter_o": "O",
    "letter_p": "P",
    "letter_q": "Q",
    "letter_r": "R",
    "letter_s": "S",
    "letter_t": "T",
    "letter_u": "U",
    "letter_v": "V",
    "letter_w": "W",
    "letter_x": "X",
    "letter_y": "Y",
    "letter_z": "Z",
}

AUDIO_ENTRIES += [(name, text, _EN_VOICE) for name, text in _EN_MAP.items()]

# ---------------------------------------------------------------------------
# Hindi — hi-IN-SwaraNeural
# ---------------------------------------------------------------------------
_HI_VOICE = "hi-IN-SwaraNeural"
_HI_MAP = {
    # Vowels
    "hi_vowel_a":   "अ",
    "hi_vowel_aa":  "आ",
    "hi_vowel_i":   "इ",
    "hi_vowel_ii":  "ई",
    "hi_vowel_u":   "उ",
    "hi_vowel_uu":  "ऊ",
    "hi_vowel_ri":  "ऋ",
    "hi_vowel_e":   "ए",
    "hi_vowel_ai":  "ऐ",
    "hi_vowel_o":   "ओ",
    "hi_vowel_au":  "औ",
    "hi_vowel_am":  "अं",
    "hi_vowel_ah":  "अः",
    # Consonants
    "hi_consonant_ka":   "क",
    "hi_consonant_kha":  "ख",
    "hi_consonant_ga":   "ग",
    "hi_consonant_gha":  "घ",
    "hi_consonant_nga":  "ङ",
    "hi_consonant_cha":  "च",
    "hi_consonant_chha": "छ",
    "hi_consonant_ja":   "ज",
    "hi_consonant_jha":  "झ",
    "hi_consonant_nya":  "ञ",
    "hi_consonant_ta":   "ट",
    "hi_consonant_tha":  "ठ",
    "hi_consonant_da":   "ड",
    "hi_consonant_dha":  "ढ",
    "hi_consonant_na":   "ण",
    "hi_consonant_ta2":  "त",
    "hi_consonant_tha2": "थ",
    "hi_consonant_da2":  "द",
    "hi_consonant_dha2": "ध",
    "hi_consonant_na2":  "न",
    "hi_consonant_pa":   "प",
    "hi_consonant_pha":  "फ",
    "hi_consonant_ba":   "ब",
    "hi_consonant_bha":  "भ",
    "hi_consonant_ma":   "म",
    "hi_consonant_ya":   "य",
    "hi_consonant_ra":   "र",
    "hi_consonant_la":   "ल",
    "hi_consonant_va":   "व",
    "hi_consonant_sha":  "श",
    "hi_consonant_ssa":  "ष",
    "hi_consonant_sa":   "स",
    "hi_consonant_ha":   "ह",
    "hi_consonant_ksha": "क्ष",
    "hi_consonant_tra":  "त्र",
    "hi_consonant_gya":  "ज्ञ",
}

AUDIO_ENTRIES += [(name, text, _HI_VOICE) for name, text in _HI_MAP.items()]

# ---------------------------------------------------------------------------
# Tamil — ta-IN-PallaviNeural
# ---------------------------------------------------------------------------
_TA_VOICE = "ta-IN-PallaviNeural"
_TA_MAP = {
    # Vowels
    "ta_vowel_a":   "அ",
    "ta_vowel_aa":  "ஆ",
    "ta_vowel_i":   "இ",
    "ta_vowel_ii":  "ஈ",
    "ta_vowel_u":   "உ",
    "ta_vowel_uu":  "ஊ",
    "ta_vowel_e":   "எ",
    "ta_vowel_ee":  "ஏ",
    "ta_vowel_ai":  "ஐ",
    "ta_vowel_o":   "ஒ",
    "ta_vowel_oo":  "ஓ",
    "ta_vowel_au":  "ஔ",
    # Consonants
    "ta_consonant_ka":  "க",
    "ta_consonant_nga": "ங",
    "ta_consonant_sa":  "ச",
    "ta_consonant_nya": "ஞ",
    "ta_consonant_da":  "ட",
    "ta_consonant_na":  "ண",
    "ta_consonant_tha": "த",
    "ta_consonant_na2": "ந",
    "ta_consonant_pa":  "ப",
    "ta_consonant_ma":  "ம",
    "ta_consonant_ya":  "ய",
    "ta_consonant_ra":  "ர",
    "ta_consonant_la":  "ல",
    "ta_consonant_va":  "வ",
    "ta_consonant_zha": "ழ",
    "ta_consonant_lla": "ள",
    "ta_consonant_rra": "ற",
    "ta_consonant_na3": "ன",
}

AUDIO_ENTRIES += [(name, text, _TA_VOICE) for name, text in _TA_MAP.items()]


async def generate_all():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    total = len(AUDIO_ENTRIES)
    for i, (name, text, voice) in enumerate(AUDIO_ENTRIES, 1):
        out_path = os.path.join(OUTPUT_DIR, f"{name}.mp3")
        if os.path.exists(out_path):
            print(f"[{i}/{total}] {name}.mp3  (skipped — already exists)")
            continue
        print(f"[{i}/{total}] {name}.mp3")
        try:
            communicate = edge_tts.Communicate(text, voice)
            await communicate.save(out_path)
        except Exception as e:
            print(f"  ERROR: {e}")
    print("\nDone! Files written to:", OUTPUT_DIR)


if __name__ == "__main__":
    asyncio.run(generate_all())
