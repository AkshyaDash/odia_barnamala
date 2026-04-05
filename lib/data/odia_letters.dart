import 'package:flutter/material.dart';
import '../models/letter.dart';

const List<Color> _pastelColors = [
  Color(0xFFFFB3BA), // pastel pink
  Color(0xFFFFDFBA), // pastel peach
  Color(0xFFFFFFBA), // pastel yellow
  Color(0xFFBAFFBA), // pastel mint
  Color(0xFFBAEEFF), // pastel sky blue
  Color(0xFFCCBAFF), // pastel lavender
  Color(0xFFFFBAF0), // pastel rose
  Color(0xFFBAFFEE), // pastel aqua
];

Color _color(int index) => _pastelColors[index % _pastelColors.length];

final List<OdiaLetter> odiaVowels = [
  OdiaLetter(character: 'ଅ', name: 'A',   audioPath: 'assets/audio/vowel_a.mp3',   tileColor: _color(0),  isVowel: true),
  OdiaLetter(character: 'ଆ', name: 'Aa',  audioPath: 'assets/audio/vowel_aa.mp3',  tileColor: _color(1),  isVowel: true),
  OdiaLetter(character: 'ଇ', name: 'I',   audioPath: 'assets/audio/vowel_i.mp3',   tileColor: _color(2),  isVowel: true),
  OdiaLetter(character: 'ଈ', name: 'Ii',  audioPath: 'assets/audio/vowel_ii.mp3',  tileColor: _color(3),  isVowel: true),
  OdiaLetter(character: 'ଉ', name: 'U',   audioPath: 'assets/audio/vowel_u.mp3',   tileColor: _color(4),  isVowel: true),
  OdiaLetter(character: 'ଊ', name: 'Uu',  audioPath: 'assets/audio/vowel_uu.mp3',  tileColor: _color(5),  isVowel: true),
  OdiaLetter(character: 'ଋ', name: 'Ru',  audioPath: 'assets/audio/vowel_ru.mp3',  tileColor: _color(6),  isVowel: true),
  OdiaLetter(character: 'ଏ', name: 'E',   audioPath: 'assets/audio/vowel_e.mp3',   tileColor: _color(7),  isVowel: true),
  OdiaLetter(character: 'ଐ', name: 'Ai',  audioPath: 'assets/audio/vowel_ai.mp3',  tileColor: _color(0),  isVowel: true),
  OdiaLetter(character: 'ଓ', name: 'O',   audioPath: 'assets/audio/vowel_o.mp3',   tileColor: _color(1),  isVowel: true),
  OdiaLetter(character: 'ଔ', name: 'Au',  audioPath: 'assets/audio/vowel_au.mp3',  tileColor: _color(2),  isVowel: true),
  OdiaLetter(character: 'ଅଂ', name: 'Am', audioPath: 'assets/audio/vowel_am.mp3',  tileColor: _color(3),  isVowel: true),
  OdiaLetter(character: 'ଅଃ', name: 'Ah', audioPath: 'assets/audio/vowel_ah.mp3',  tileColor: _color(4),  isVowel: true),
];

final List<OdiaLetter> odiaConsonants = [
  OdiaLetter(character: 'କ', name: 'Ka',  audioPath: 'assets/audio/consonant_ka.mp3',  tileColor: _color(0),  isVowel: false),
  OdiaLetter(character: 'ଖ', name: 'Kha', audioPath: 'assets/audio/consonant_kha.mp3', tileColor: _color(1),  isVowel: false),
  OdiaLetter(character: 'ଗ', name: 'Ga',  audioPath: 'assets/audio/consonant_ga.mp3',  tileColor: _color(2),  isVowel: false),
  OdiaLetter(character: 'ଘ', name: 'Gha', audioPath: 'assets/audio/consonant_gha.mp3', tileColor: _color(3),  isVowel: false),
  OdiaLetter(character: 'ଙ', name: 'Nga', audioPath: 'assets/audio/consonant_nga.mp3', tileColor: _color(4),  isVowel: false),
  OdiaLetter(character: 'ଚ', name: 'Cha', audioPath: 'assets/audio/consonant_cha.mp3', tileColor: _color(5),  isVowel: false),
  OdiaLetter(character: 'ଛ', name: 'Chha',audioPath: 'assets/audio/consonant_chha.mp3',tileColor: _color(6),  isVowel: false),
  OdiaLetter(character: 'ଜ', name: 'Ja',  audioPath: 'assets/audio/consonant_ja.mp3',  tileColor: _color(7),  isVowel: false),
  OdiaLetter(character: 'ଝ', name: 'Jha', audioPath: 'assets/audio/consonant_jha.mp3', tileColor: _color(0),  isVowel: false),
  OdiaLetter(character: 'ଞ', name: 'Nya', audioPath: 'assets/audio/consonant_nya.mp3', tileColor: _color(1),  isVowel: false),
  OdiaLetter(character: 'ଟ', name: 'Ta',  audioPath: 'assets/audio/consonant_ta.mp3',  tileColor: _color(2),  isVowel: false),
  OdiaLetter(character: 'ଠ', name: 'Tha', audioPath: 'assets/audio/consonant_tha.mp3', tileColor: _color(3),  isVowel: false),
  OdiaLetter(character: 'ଡ', name: 'Da',  audioPath: 'assets/audio/consonant_da.mp3',  tileColor: _color(4),  isVowel: false),
  OdiaLetter(character: 'ଢ', name: 'Dha', audioPath: 'assets/audio/consonant_dha.mp3', tileColor: _color(5),  isVowel: false),
  OdiaLetter(character: 'ଣ', name: 'Na',  audioPath: 'assets/audio/consonant_na.mp3',  tileColor: _color(6),  isVowel: false),
  OdiaLetter(character: 'ତ', name: 'Ta2', audioPath: 'assets/audio/consonant_ta2.mp3', tileColor: _color(7),  isVowel: false),
  OdiaLetter(character: 'ଥ', name: 'Tha2',audioPath: 'assets/audio/consonant_tha2.mp3',tileColor: _color(0),  isVowel: false),
  OdiaLetter(character: 'ଦ', name: 'Da2', audioPath: 'assets/audio/consonant_da2.mp3', tileColor: _color(1),  isVowel: false),
  OdiaLetter(character: 'ଧ', name: 'Dha2',audioPath: 'assets/audio/consonant_dha2.mp3',tileColor: _color(2),  isVowel: false),
  OdiaLetter(character: 'ନ', name: 'Na2', audioPath: 'assets/audio/consonant_na2.mp3', tileColor: _color(3),  isVowel: false),
  OdiaLetter(character: 'ପ', name: 'Pa',  audioPath: 'assets/audio/consonant_pa.mp3',  tileColor: _color(4),  isVowel: false),
  OdiaLetter(character: 'ଫ', name: 'Pha', audioPath: 'assets/audio/consonant_pha.mp3', tileColor: _color(5),  isVowel: false),
  OdiaLetter(character: 'ବ', name: 'Ba',  audioPath: 'assets/audio/consonant_ba.mp3',  tileColor: _color(6),  isVowel: false),
  OdiaLetter(character: 'ଭ', name: 'Bha', audioPath: 'assets/audio/consonant_bha.mp3', tileColor: _color(7),  isVowel: false),
  OdiaLetter(character: 'ମ', name: 'Ma',  audioPath: 'assets/audio/consonant_ma.mp3',  tileColor: _color(0),  isVowel: false),
  OdiaLetter(character: 'ଯ', name: 'Ya',  audioPath: 'assets/audio/consonant_ya.mp3',  tileColor: _color(1),  isVowel: false),
  OdiaLetter(character: 'ର', name: 'Ra',  audioPath: 'assets/audio/consonant_ra.mp3',  tileColor: _color(2),  isVowel: false),
  OdiaLetter(character: 'ଲ', name: 'La',  audioPath: 'assets/audio/consonant_la.mp3',  tileColor: _color(3),  isVowel: false),
  OdiaLetter(character: 'ଵ', name: 'Va',  audioPath: 'assets/audio/consonant_va.mp3',  tileColor: _color(4),  isVowel: false),
  OdiaLetter(character: 'ଶ', name: 'Sha', audioPath: 'assets/audio/consonant_sha.mp3', tileColor: _color(5),  isVowel: false),
  OdiaLetter(character: 'ଷ', name: 'Ssa', audioPath: 'assets/audio/consonant_ssa.mp3', tileColor: _color(6),  isVowel: false),
  OdiaLetter(character: 'ସ', name: 'Sa',  audioPath: 'assets/audio/consonant_sa.mp3',  tileColor: _color(7),  isVowel: false),
  OdiaLetter(character: 'ହ', name: 'Ha',  audioPath: 'assets/audio/consonant_ha.mp3',  tileColor: _color(0),  isVowel: false),
  OdiaLetter(character: 'ଳ', name: 'Lla', audioPath: 'assets/audio/consonant_lla.mp3', tileColor: _color(1),  isVowel: false),
  OdiaLetter(character: 'କ୍ଷ', name: 'Ksha',audioPath: 'assets/audio/consonant_ksha.mp3',tileColor: _color(2), isVowel: false),
  OdiaLetter(character: 'ଜ୍ଞ', name: 'Gya', audioPath: 'assets/audio/consonant_gya.mp3', tileColor: _color(3),  isVowel: false),
];

final List<OdiaLetter> allOdiaLetters = [...odiaVowels, ...odiaConsonants];
