import 'package:flutter/material.dart';

class LetterNode {
  LetterNode({
    required this.id,
    required this.letter,
    required this.position,
  });

  final int id;
  final String letter;
  final Offset position;
}
