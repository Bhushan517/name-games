import 'package:flutter/material.dart';

class WordLevel {
  const WordLevel({
    required this.index,
    required this.word,
    required this.emoji,
    required this.clue,
    required this.meaning,
    required this.shape,
    required this.color,
    required this.points,
    required this.category,
    required this.difficulty,
  });

  final int index;
  final String word;
  final String emoji;
  final String clue;
  final String meaning;
  final String shape;
  final Color color;
  final List<Offset> points;
  final String category;
  final String difficulty;

  int get letterCount => word.length;
}
