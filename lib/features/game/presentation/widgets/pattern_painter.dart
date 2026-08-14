import 'package:flutter/material.dart';
import '../../../../data/models/letter_node.dart';

class PatternPainter extends CustomPainter {
  const PatternPainter({
    required this.nodes,
    required this.selectedIndices,
    required this.renderArea,
    required this.lineColor,
    required this.isPatternClosed,
  });

  final List<LetterNode> nodes;
  final List<int> selectedIndices;
  final Size renderArea;
  final Color lineColor;
  final bool isPatternClosed;

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndices.isEmpty) return;

    final points = selectedIndices
        .map((i) => Offset(
              nodes[i].position.dx * renderArea.width,
              nodes[i].position.dy * renderArea.height,
            ))
        .toList();

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (isPatternClosed) {
      path.close();
    }

    // Outer glow stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor.withValues(alpha: 0.2)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Sharp inner neon path
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) =>
      oldDelegate.selectedIndices.length != selectedIndices.length ||
      oldDelegate.isPatternClosed != isPatternClosed ||
      oldDelegate.nodes != nodes;
}
