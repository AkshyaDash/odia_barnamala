#!/usr/bin/env python3
"""
Generate Odia barnamala audio files using edge-tts with Hindi voice.

Odia and Hindi share the same Sanskrit-based phonetic system, so Hindi TTS
(hi-IN-SwaraNeural) pronounces barnamala letters identically to Odia.
We pass the Devanagari equivalent of each Odia letter for correct pronunciation.

Requirements:
    pip install edge-tts

Run from the project root:
    python generate_audio.py
"""

import asyncio
import os
import edge_tts

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "assets", "audio")
VOICE = "hi-IN-SwaraNeural"  # Natural female Hindi voice

# Maps filename -> Hindi Devanagari equivalent (same sounds as Odia barnamala)
AUDIO_MAP = {
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


async def generate_all():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    total = len(AUDIO_MAP)
    for i, (name, text) in enumerate(AUDIO_MAP.items(), 1):
        out_path = os.path.join(OUTPUT_DIR, f"{name}.mp3")
        print(f"[{i}/{total}] {name}.mp3")
        try:
            communicate = edge_tts.Communicate(text, VOICE)
            await communicate.save(out_path)
        except Exception as e:
            print(f"  ERROR: {e}")
    print("\nDone! Files written to:", OUTPUT_DIR)


if __name__ == "__main__":
    asyncio.run(generate_all())
