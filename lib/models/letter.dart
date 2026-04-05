import 'package:flutter/material.dart';

class OdiaLetter {
  final String character;
  final String name;
  final String audioPath;
  final Color tileColor;
  final bool isVowel;

  const OdiaLetter({
    required this.character,
    required this.name,
    required this.audioPath,
    required this.tileColor,
    required this.isVowel,
  });
}
