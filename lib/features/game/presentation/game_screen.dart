import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/challenge_mode.dart';
import '../../../data/models/generated_challenge.dart';
import '../../../data/repositories/challenge_repository.dart';
import '../../../shared/widgets/space_background.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/audio_service.dart';
import '../controller/game_controller.dart';
import 'widgets/animated_letter_node.dart';
import 'widgets/clue_card.dart';
import 'widgets/game_action_buttons.dart';
import 'widgets/level_complete_dialog.dart';
import 'widgets/lives_indicator.dart';
import 'widgets/missing_letter_board.dart';
import 'widgets/mode_headers/listen_spell_header.dart';
import 'widgets/mode_headers/memory_header.dart';
import 'widgets/mode_headers/timer_bar.dart';
import 'widgets/pattern_painter.dart';
import 'widgets/word_slots.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.challenge,
    required this.repository,
    this.isDailyMode = false,
  });

  final GeneratedChallenge challenge;
  final ChallengeRepository repository;

  /// When true, completing this level does NOT unlock or skip campaign levels.
  final bool isDailyMode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final GameController _controller;
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AudioService().playBgm('gameplay_music.wav');
    _controller = GameController(
      challenge: widget.challenge,
      repository: widget.repository,
      isDailyMode: widget.isDailyMode,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      _controller.resumeTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeController.dispose();
    _controller.dispose();
    AudioService().playBgm('menu_music.wav');
    super.dispose();
  }

  bool _isOutOfLivesDialogVisible = false;
  bool _isAdLoading = false;

  void _showOutOfLivesDialogIfNeeded() {
    if (_isOutOfLivesDialogVisible || !mounted) return;

    _isOutOfLivesDialogVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          AppStrings.outOfLives,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(AppStrings.outOfLivesMessage),
        actions: [
          if (_controller.canUseRewardedLife &&
              AdService().isRewardedLifeAdReady)
            TextButton.icon(
              onPressed: () {
                _isOutOfLivesDialogVisible = false;
                Navigator.pop(context);
                AdService().showRewardedLifeAd(
                  onRewardEarned: () {
                    _controller.grantRewardedLife();
                  },
                  onAdClosed: () {
                    if (mounted &&
                        _controller.validationState ==
                            GameValidationState.outOfLives) {
                      _showOutOfLivesDialogIfNeeded();
                    }
                  },
                );
              },
              icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
              label: const Text('WATCH AD FOR +1 LIFE'),
            ),
          TextButton(
            onPressed: AudioService.withSound(() {
              _isOutOfLivesDialogVisible = false;
              Navigator.pop(context); // Close dialog
              Navigator.pop(
                  context); // Return to Level Selection / previous screen
            }),
            child: const Text(AppStrings.exitLevel),
          ),
          FilledButton(
            onPressed: AudioService.withSound(() {
              _isOutOfLivesDialogVisible = false;
              Navigator.pop(context); // Close dialog
              _controller.resetLives();
            }),
            child: const Text(AppStrings.tryAgain),
          ),
        ],
      ),
    ).then((_) {
      _isOutOfLivesDialogVisible = false;
    });
  }

  Future<void> _handleCheckWord() async {
    final result = await _controller.validateSpelling();

    if (!mounted) return;

    if (result == GameValidationState.incomplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.challenge.mode == ChallengeMode.missingLetter
                ? 'Fill all missing letters first!'
                : 'Use all ${widget.challenge.letterCount} letters first!',
          ),
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
          challenge: widget.challenge,
          stars: stars,
          onContinue: () {
            Navigator.pop(context); // Close dialog
            if (!widget.isDailyMode) {
              AdService().recordCampaignCompletionAndShowInterstitialIfNeeded(
                onContinue: () {
                  if (mounted) {
                    Navigator.pop(context, stars); // Return to Level Selection
                  }
                },
              );
            } else {
              Navigator.pop(context, stars); // Return to Level Selection
            }
          },
        ),
      );
      return;
    }

    // Wrong answer shake
    await _shakeController.forward(from: 0);

    if (result == GameValidationState.outOfLives && mounted) {
      _showOutOfLivesDialogIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.challenge.themeColor;

    return Scaffold(
      body: SpaceBackground(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            // Auto-show Out of Lives dialog when the timed-mode countdown
            // removes the last life (timeout path bypasses _handleCheckWord).
            if (_controller.validationState == GameValidationState.outOfLives &&
                !_controller.isCompleted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showOutOfLivesDialogIfNeeded();
              });
            }
            return AnimatedBuilder(
              animation: _shakeController,
              builder: (_, child) => Transform.translate(
                offset: Offset(sin(_shakeController.value * pi * 6) * 10, 0),
                child: child,
              ),
              child: Column(
                children: [
                  // --- Header Row ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: AudioService.withSound(
                              () => Navigator.pop(context)),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    'LEVEL ${widget.challenge.challengeNumber} / 500',
                                    style: TextStyle(
                                      color: themeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: themeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.challenge.mode.shortName,
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: themeColor,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _controller.isCompleted
                                    ? widget.challenge.patternTemplate.name
                                        .toUpperCase()
                                    : 'MYSTERY PATTERN',
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

                  // --- Mode-Specific Header Additions ---
                  if (widget.challenge.mode == ChallengeMode.timed)
                    TimerBar(
                      secondsRemaining: _controller.timeRemaining,
                      totalSeconds:
                          widget.challenge.difficultyConfig.timerSeconds,
                    ),

                  if (widget.challenge.mode == ChallengeMode.memory)
                    MemoryHeader(
                      isRevealed: _controller.isMemoryRevealed,
                      secondsLeft: _controller.memorySecondsLeft,
                      onReplay: _controller.replayMemoryPreview,
                    ),

                  if (widget.challenge.mode == ChallengeMode.listenSpell)
                    ListenSpellHeader(
                      onSpeak: _controller.speakWordOrClue,
                    ),

                  // --- Clue Card ---
                  ClueCard(
                    level: widget.challenge.wordContent,
                    isNextHintFree: _controller.isNextHintFree,
                    canUseHint: _controller.canUseHint,
                    totalHintsUsed: _controller.totalHintsUsed,
                    maxHints: _controller.maxHints,
                    onHintTap: () {
                      if (_isAdLoading) return;

                      if (_controller.isNextHintFree) {
                        _controller.grantHint();
                      } else {
                        if (!AdService().isRewardedHintAdReady) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Ad is currently unavailable. Please try again later.')),
                          );
                          return;
                        }

                        _isAdLoading = true;
                        AdService().showRewardedHintAd(
                          onRewardEarned: () {
                            _controller.grantHint();
                          },
                          onAdClosed: () {
                            if (mounted) {
                              setState(() {
                                _isAdLoading = false;
                              });
                            }
                          },
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 4),

                  // --- Word Slots (for non-missing letter modes) ---
                  if (widget.challenge.mode != ChallengeMode.missingLetter)
                    WordSlots(
                      letterCount: widget.challenge.letterCount,
                      selectedIndices: _controller.selectedIndices,
                      nodes: _controller.nodes,
                      themeColor: themeColor,
                      revealedHintIndices: _controller.revealedHintIndices,
                    ),

                  // --- Interactive Playfield ---
                  Expanded(
                    child: widget.challenge.mode == ChallengeMode.missingLetter
                        ? MissingLetterBoard(
                            word: widget.challenge.word,
                            missingIndices: _controller.missingIndices,
                            filledLetters: _controller.filledMissingLetters,
                            choices: _controller.missingLetterChoices,
                            themeColor: themeColor,
                            onLetterSelected: _controller.fillMissingLetter,
                          )
                        : LayoutBuilder(
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
                                        selectedIndices:
                                            _controller.selectedIndices,
                                        renderArea: Size(areaWidth, areaHeight),
                                        lineColor: themeColor,
                                        isPatternClosed:
                                            _controller.isCompleted,
                                      ),
                                    ),
                                  ),
                                  ...List.generate(_controller.nodes.length,
                                      (index) {
                                    final node = _controller.nodes[index];
                                    final isSelected =
                                        _controller.isSelected(index);
                                    final leftPos =
                                        (node.position.dx * areaWidth -
                                                nodeRadius)
                                            .clamp(4.0,
                                                areaWidth - nodeRadius * 2 - 4);
                                    final topPos = (node.position.dy *
                                                areaHeight -
                                            nodeRadius)
                                        .clamp(4.0,
                                            areaHeight - nodeRadius * 2 - 4);

                                    final isHiddenInMemory =
                                        widget.challenge.mode ==
                                                ChallengeMode.memory &&
                                            !_controller.isMemoryRevealed &&
                                            !isSelected;

                                    return AnimatedPositioned(
                                      duration:
                                          const Duration(milliseconds: 420),
                                      curve: Curves.easeOutBack,
                                      left: leftPos,
                                      top: topPos,
                                      child: AnimatedLetterNode(
                                        letter: isHiddenInMemory
                                            ? '?'
                                            : node.letter,
                                        isSelected: isSelected,
                                        themeColor: themeColor,
                                        radius: nodeRadius,
                                        onTap: () =>
                                            _controller.selectLetter(index),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                  ),

                  // --- Action Buttons ---
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
