import 'package:flutter/material.dart';

class PatternTemplate {
  const PatternTemplate({
    required this.name,
    required this.letterCount,
    required this.points,
    this.closeShape = true,
  });

  final String name;
  final int letterCount;
  final List<Offset> points;
  final bool closeShape;
}
