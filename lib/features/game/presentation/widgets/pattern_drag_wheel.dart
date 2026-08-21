import 'package:flutter/material.dart';
import '../../../../data/models/letter_node.dart';
import 'animated_letter_node.dart';
import 'pattern_painter.dart';

class PatternDragWheel extends StatefulWidget {
  const PatternDragWheel({
    super.key,
    required this.nodes,
    required this.selectedIndices,
    required this.themeColor,
    required this.isCompleted,
    required this.isMemoryMode,
    required this.isMemoryRevealed,
    required this.onNodeSelected,
  });

  final List<LetterNode> nodes;
  final List<int?> selectedIndices;
  final Color themeColor;
  final bool isCompleted;
  final bool isMemoryMode;
  final bool isMemoryRevealed;
  final ValueChanged<int> onNodeSelected;

  @override
  State<PatternDragWheel> createState() => _PatternDragWheelState();
}

class _PatternDragWheelState extends State<PatternDragWheel> {
  Offset? _dragPosition;

  void _handlePanUpdate(Offset localPos, Size areaSize, double nodeRadius) {
    setState(() {
      _dragPosition = localPos;
    });

    final hitRadius = nodeRadius * 1.7;

    for (int i = 0; i < widget.nodes.length; i++) {
      final nodeCenter = Offset(
        widget.nodes[i].position.dx * areaSize.width,
        widget.nodes[i].position.dy * areaSize.height,
      );

      final distance = (localPos - nodeCenter).distance;
      if (distance <= hitRadius) {
        widget.onNodeSelected(i);
        break;
      }
    }
  }

  void _handlePanEnd() {
    setState(() {
      _dragPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaWidth = constraints.maxWidth;
        final areaHeight = constraints.maxHeight;
        const nodeRadius = 28.0;
        final areaSize = Size(areaWidth, areaHeight);

        return GestureDetector(
          onPanStart: (details) =>
              _handlePanUpdate(details.localPosition, areaSize, nodeRadius),
          onPanUpdate: (details) =>
              _handlePanUpdate(details.localPosition, areaSize, nodeRadius),
          onPanEnd: (_) => _handlePanEnd(),
          onPanCancel: () => _handlePanEnd(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Canvas for connecting lines & drag line trail
              Positioned.fill(
                child: CustomPaint(
                  painter: PatternPainter(
                    nodes: widget.nodes,
                    selectedIndices: widget.selectedIndices,
                    renderArea: areaSize,
                    lineColor: widget.themeColor,
                    isPatternClosed: widget.isCompleted,
                    dragPosition: _dragPosition,
                  ),
                ),
              ),

              // Animated Letter Nodes
              ...List.generate(widget.nodes.length, (index) {
                final node = widget.nodes[index];
                final isSelected = widget.selectedIndices.contains(index);
                final leftPos = (node.position.dx * areaWidth - nodeRadius)
                    .clamp(4.0, areaWidth - nodeRadius * 2 - 4);
                final topPos = (node.position.dy * areaHeight - nodeRadius)
                    .clamp(4.0, areaHeight - nodeRadius * 2 - 4);

                final isHiddenInMemory = widget.isMemoryMode &&
                    !widget.isMemoryRevealed &&
                    !isSelected;

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutBack,
                  left: leftPos,
                  top: topPos,
                  child: AnimatedLetterNode(
                    letter: isHiddenInMemory ? '?' : node.letter,
                    isSelected: isSelected,
                    themeColor: widget.themeColor,
                    radius: nodeRadius,
                    onTap: () => widget.onNodeSelected(index),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
