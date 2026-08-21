import 'package:flutter/material.dart';
import '../../../../data/models/letter_node.dart';

class PatternPainter extends CustomPainter {
  const PatternPainter({
    required this.nodes,
    required this.selectedIndices,
    required this.renderArea,
    required this.lineColor,
    required this.isPatternClosed,
    this.dragPosition,
  });

  final List<LetterNode> nodes;
  final List<int?> selectedIndices;
  final Size renderArea;
  final Color lineColor;
  final bool isPatternClosed;
  final Offset? dragPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final validIndices = selectedIndices.whereType<int>().toList();
    if (validIndices.isEmpty) return;

    final points = validIndices
        .map((i) => Offset(
              nodes[i].position.dx * renderArea.width,
              nodes[i].position.dy * renderArea.height,
            ))
        .toList();

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (dragPosition != null && !isPatternClosed) {
      path.lineTo(dragPosition!.dx, dragPosition!.dy);
    } else if (isPatternClosed) {
      path.close();
    }

    // Outer glow stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor.withValues(alpha: 0.35)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Sharp inner neon path
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Draw active glowing pointer dot at drag position
    if (dragPosition != null && !isPatternClosed) {
      canvas.drawCircle(
        dragPosition!,
        9.0,
        Paint()..color = lineColor.withValues(alpha: 0.4),
      );
      canvas.drawCircle(
        dragPosition!,
        4.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) {
    final oldValidCount =
        oldDelegate.selectedIndices.where((e) => e != null).length;
    final newValidCount = selectedIndices.where((e) => e != null).length;
    return oldValidCount != newValidCount ||
        oldDelegate.isPatternClosed != isPatternClosed ||
        oldDelegate.nodes != nodes ||
        oldDelegate.dragPosition != dragPosition;
  }
}

