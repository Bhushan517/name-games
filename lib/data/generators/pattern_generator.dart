import 'package:flutter/material.dart';
import '../models/pattern_template.dart';

class PatternGenerator {
  PatternGenerator._();

  static final Map<String, PatternTemplate> _templates = {
    // --- 4 LETTERS ---
    'diamond': const PatternTemplate(
      name: 'diamond',
      letterCount: 4,
      points: [
        Offset(0.50, 0.10), // Top
        Offset(0.88, 0.50), // Right
        Offset(0.50, 0.90), // Bottom
        Offset(0.12, 0.50), // Left
      ],
      closeShape: true,
    ),
    'square': const PatternTemplate(
      name: 'square',
      letterCount: 4,
      points: [
        Offset(0.18, 0.18), // Top-left
        Offset(0.82, 0.18), // Top-right
        Offset(0.82, 0.82), // Bottom-right
        Offset(0.18, 0.82), // Bottom-left
      ],
      closeShape: true,
    ),
    'kite': const PatternTemplate(
      name: 'kite',
      letterCount: 4,
      points: [
        Offset(0.50, 0.08), // Top
        Offset(0.85, 0.38), // Right wing
        Offset(0.50, 0.92), // Tail
        Offset(0.15, 0.38), // Left wing
      ],
      closeShape: true,
    ),

    // --- 5 LETTERS ---
    'star': const PatternTemplate(
      name: 'star',
      letterCount: 5,
      points: [
        Offset(0.49, 0.04), // Top tip
        Offset(0.61, 0.62), // Lower right
        Offset(0.08, 0.25), // Upper left
        Offset(0.90, 0.25), // Upper right
        Offset(0.37, 0.62), // Lower left
      ],
      closeShape: true,
    ),
    'house': const PatternTemplate(
      name: 'house',
      letterCount: 5,
      points: [
        Offset(0.15, 0.48), // Roof left
        Offset(0.50, 0.08), // Roof peak
        Offset(0.85, 0.48), // Roof right
        Offset(0.85, 0.88), // Base right
        Offset(0.15, 0.88), // Base left
      ],
      closeShape: true,
    ),
    'crown': const PatternTemplate(
      name: 'crown',
      letterCount: 5,
      points: [
        Offset(0.08, 0.80), // Bottom left
        Offset(0.18, 0.20), // Left peak
        Offset(0.50, 0.62), // Center dip
        Offset(0.82, 0.20), // Right peak
        Offset(0.92, 0.80), // Bottom right
      ],
      closeShape: true,
    ),
    'heart': const PatternTemplate(
      name: 'heart',
      letterCount: 5,
      points: [
        Offset(0.50, 0.88), // Bottom point
        Offset(0.08, 0.42), // Left curve
        Offset(0.28, 0.15), // Left top
        Offset(0.50, 0.36), // Center dip
        Offset(0.72, 0.15), // Right top
      ],
      closeShape: true,
    ),
    'tree': const PatternTemplate(
      name: 'tree',
      letterCount: 5,
      points: [
        Offset(0.50, 0.05), // Top peak
        Offset(0.50, 0.86), // Trunk base
        Offset(0.08, 0.55), // Left branch
        Offset(0.50, 0.24), // Center node
        Offset(0.92, 0.55), // Right branch
      ],
      closeShape: true,
    ),

    // --- 6 LETTERS ---
    'hexagon': const PatternTemplate(
      name: 'hexagon',
      letterCount: 6,
      points: [
        Offset(0.50, 0.08), // Top
        Offset(0.88, 0.28), // Top right
        Offset(0.88, 0.72), // Bottom right
        Offset(0.50, 0.92), // Bottom
        Offset(0.12, 0.72), // Bottom left
        Offset(0.12, 0.28), // Top left
      ],
      closeShape: true,
    ),
    'lightning': const PatternTemplate(
      name: 'lightning',
      letterCount: 6,
      points: [
        Offset(0.58, 0.08), // Start
        Offset(0.25, 0.45), // Jag in
        Offset(0.65, 0.45), // Jag out
        Offset(0.35, 0.72), // Second jag
        Offset(0.75, 0.72), // Second out
        Offset(0.42, 0.94), // Bottom tip
      ],
      closeShape: false,
    ),
    'rocket': const PatternTemplate(
      name: 'rocket',
      letterCount: 6,
      points: [
        Offset(0.50, 0.06), // Nose cone
        Offset(0.78, 0.38), // Right fuselage
        Offset(0.88, 0.88), // Right fin
        Offset(0.50, 0.76), // Thruster
        Offset(0.12, 0.88), // Left fin
        Offset(0.22, 0.38), // Left fuselage
      ],
      closeShape: true,
    ),

    // --- 7 LETTERS ---
    'spiral': const PatternTemplate(
      name: 'spiral',
      letterCount: 7,
      points: [
        Offset(0.50, 0.50), // Center
        Offset(0.50, 0.30), // Up
        Offset(0.72, 0.35), // Up-right
        Offset(0.78, 0.65), // Down-right
        Offset(0.50, 0.85), // Down
        Offset(0.22, 0.65), // Down-left
        Offset(0.18, 0.20), // Outer spiral end
      ],
      closeShape: false,
    ),
    'mountain': const PatternTemplate(
      name: 'mountain',
      letterCount: 7,
      points: [
        Offset(0.08, 0.88), // Base left
        Offset(0.28, 0.28), // Peak 1
        Offset(0.45, 0.60), // Dip
        Offset(0.65, 0.10), // Main peak
        Offset(0.80, 0.50), // Small peak
        Offset(0.92, 0.88), // Base right
        Offset(0.50, 0.88), // Center base
      ],
      closeShape: true,
    ),
    'wave': const PatternTemplate(
      name: 'wave',
      letterCount: 7,
      points: [
        Offset(0.08, 0.65), // Start low
        Offset(0.22, 0.25), // Crest 1
        Offset(0.38, 0.70), // Trough 1
        Offset(0.52, 0.20), // Crest 2
        Offset(0.68, 0.70), // Trough 2
        Offset(0.82, 0.25), // Crest 3
        Offset(0.92, 0.65), // End low
      ],
      closeShape: false,
    ),

    // --- 8 LETTERS ---
    'flower': const PatternTemplate(
      name: 'flower',
      letterCount: 8,
      points: [
        Offset(0.50, 0.08), // Top petal
        Offset(0.78, 0.20), // Top-right petal
        Offset(0.90, 0.50), // Right petal
        Offset(0.78, 0.80), // Bottom-right petal
        Offset(0.50, 0.92), // Bottom petal
        Offset(0.22, 0.80), // Bottom-left petal
        Offset(0.10, 0.50), // Left petal
        Offset(0.22, 0.20), // Top-left petal
      ],
      closeShape: true,
    ),
    'octagon': const PatternTemplate(
      name: 'octagon',
      letterCount: 8,
      points: [
        Offset(0.35, 0.08), // Top left
        Offset(0.65, 0.08), // Top right
        Offset(0.90, 0.35), // Right top
        Offset(0.90, 0.65), // Right bottom
        Offset(0.65, 0.92), // Bottom right
        Offset(0.35, 0.92), // Bottom left
        Offset(0.10, 0.65), // Left bottom
        Offset(0.10, 0.35), // Left top
      ],
      closeShape: true,
    ),
    'butterfly': const PatternTemplate(
      name: 'butterfly',
      letterCount: 8,
      points: [
        Offset(0.50, 0.15), // Head
        Offset(0.85, 0.10), // Top-right wing
        Offset(0.92, 0.50), // Mid-right wing
        Offset(0.75, 0.88), // Bottom-right wing
        Offset(0.50, 0.70), // Body tail
        Offset(0.25, 0.88), // Bottom-left wing
        Offset(0.08, 0.50), // Mid-left wing
        Offset(0.15, 0.10), // Top-left wing
      ],
      closeShape: true,
    ),
  };

  static PatternTemplate getTemplate(String name, int letterCount) {
    final key = name.toLowerCase().trim();
    if (_templates.containsKey(key)) {
      return _templates[key]!;
    }
    return _generateFallbackTemplate(letterCount);
  }

  static PatternTemplate _generateFallbackTemplate(int letterCount) {
    final points = <Offset>[];
    const center = Offset(0.50, 0.50);
    const radius = 0.40;
    for (var i = 0; i < letterCount; i++) {
      final angle =
          (i / letterCount) * 2 * 3.141592653589793 - (3.141592653589793 / 2);
      final x = (center.dx +
              radius * 0.9 * (angle >= 0 ? 1 : 1) * (1 + 0.1 * (i % 2)))
          .clamp(0.10, 0.90);
      final y =
          (center.dy + radius * 0.9 * (angle >= 0 ? 1 : 1)).clamp(0.10, 0.90);
      points.add(Offset(x, y));
    }
    return PatternTemplate(
      name: 'polygon_$letterCount',
      letterCount: letterCount,
      points: points,
      closeShape: true,
    );
  }
}
