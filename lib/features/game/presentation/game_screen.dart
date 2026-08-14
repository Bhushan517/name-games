import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/word_level.dart';
import '../../../data/repositories/level_repository.dart';
import '../../../shared/widgets/space_background.dart';
import '../controller/game_controller.dart';
import 'widgets/animated_letter_node.dart';
import 'widgets/clue_card.dart';
import 'widgets/game_action_buttons.dart';
import 'widgets/level_complete_dialog.dart';
import 'widgets/lives_indicator.dart';
import 'widgets/pattern_painter.dart';
import 'widgets/word_slots.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.repository,
  });

  final WordLevel level;
  final LevelRepository repository;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameController _controller;
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      level: widget.level,
      repository: widget.repository,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCheckWord() async {
    final result = await _controller.validateSpelling();

    if (!mounted) return;

    if (result == GameValidationState.incomplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.useAllLetters),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (result == GameValidationState.correct) {
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;

      final stars = _controller.calculateStars();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => LevelCompleteDialog(
          level: widget.level,
          stars: stars,
          onContinue: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context, stars); // Return to LevelSelection
          },
        ),
      );
      return;
    }

    // Wrong answer -> shake screen
    await _shakeController.forward(from: 0);

    if (result == GameValidationState.outOfLives && mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text(
            AppStrings.outOfLives,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(AppStrings.outOfLivesMessage),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _controller.resetLives();
              },
              child: const Text(AppStrings.tryAgain),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return AnimatedBuilder(
              animation: _shakeController,
              builder: (_, child) => Transform.translate(
                offset: Offset(sin(_shakeController.value * pi * 6) * 10, 0),
                child: child,
              ),
              child: Column(
                children: [
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LEVEL ${widget.level.index + 1} / 5',
                                style: TextStyle(
                                  color: widget.level.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.level.shape,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LivesIndicator(currentLives: _controller.lives),
                      ],
                    ),
                  ),

                  // Clue Card
                  ClueCard(
                    level: widget.level,
                    hintUsed: _controller.hintUsed,
                    hasSelectedLetters: _controller.selectedIndices.isNotEmpty,
                    onHintTap: _controller.useHint,
                  ),

                  const SizedBox(height: 4),

                  // Word Slots
                  WordSlots(
                    letterCount: widget.level.letterCount,
                    selectedIndices: _controller.selectedIndices,
                    nodes: _controller.nodes,
                    themeColor: widget.level.color,
                    hintUsed: _controller.hintUsed,
                    firstLetter: widget.level.word[0],
                  ),

                  // Interactive Playfield
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, constraints) {
                        final areaWidth = constraints.maxWidth;
                        final areaHeight = constraints.maxHeight;
                        const nodeRadius = 27.0;

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: PatternPainter(
                                  nodes: _controller.nodes,
                                  selectedIndices: _controller.selectedIndices,
                                  renderArea: Size(areaWidth, areaHeight),
                                  lineColor: widget.level.color,
                                  isPatternClosed: _controller.isCompleted,
                                ),
                              ),
                            ),
                            ...List.generate(_controller.nodes.length, (index) {
                              final node = _controller.nodes[index];
                              final isSelected = _controller.isSelected(index);
                              final leftPos = (node.position.dx * areaWidth -
                                      nodeRadius)
                                  .clamp(4.0, areaWidth - nodeRadius * 2 - 4);
                              final topPos = (node.position.dy * areaHeight -
                                      nodeRadius)
                                  .clamp(4.0, areaHeight - nodeRadius * 2 - 4);

                              return AnimatedPositioned(
                                duration: const Duration(milliseconds: 420),
                                curve: Curves.easeOutBack,
                                left: leftPos,
                                top: topPos,
                                child: AnimatedLetterNode(
                                  letter: node.letter,
                                  isSelected: isSelected,
                                  themeColor: widget.level.color,
                                  radius: nodeRadius,
                                  onTap: () => _controller.selectLetter(index),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),

                  // Action Buttons
                  GameActionButtons(
                    onUndo: _controller.undo,
                    onCheckWord: _handleCheckWord,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
