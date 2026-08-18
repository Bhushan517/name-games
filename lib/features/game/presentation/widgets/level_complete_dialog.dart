import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../data/models/generated_challenge.dart';

class LevelCompleteDialog extends StatefulWidget {
  const LevelCompleteDialog({
    super.key,
    required this.challenge,
    required this.stars,
    required this.onContinue,
  });

  final GeneratedChallenge challenge;
  final int stars;
  final VoidCallback onContinue;

  @override
  State<LevelCompleteDialog> createState() => _LevelCompleteDialogState();
}

class _LevelCompleteDialogState extends State<LevelCompleteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  @override
  void initState() {
    super.initState();
    AudioService().playSfx('level_complete.wav');
    for (int i = 0; i < widget.stars; i++) {
      Timer(Duration(milliseconds: 400 + i * 170), () {
        if (mounted) {
          AudioService().playSfx('star_earned.wav');
        }
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordContent = widget.challenge.wordContent;

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _animController,
        curve: Curves.elasticOut,
      ),
      child: AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: widget.challenge.themeColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        title: const Text(
          AppStrings.brilliant,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(wordContent.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    wordContent.word,
                    style: TextStyle(
                      color: widget.challenge.themeColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => TtsService.speak(
                      wordContent.pronunciation.isNotEmpty
                          ? wordContent.pronunciation
                          : wordContent.word,
                    ),
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      size: 20,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // English Meaning
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ENGLISH',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppColors.cyan,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      wordContent.meaningEnglish,
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                    const Divider(height: 14, color: Colors.white12),
                    const Text(
                      'मराठी अर्थ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      wordContent.meaningMarathi,
                      style: const TextStyle(fontSize: 12.5, height: 1.3),
                    ),
                    const Divider(height: 14, color: Colors.white12),
                    const Text(
                      'हिन्दी अर्थ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppColors.emeraldGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      wordContent.meaningHindi,
                      style: const TextStyle(fontSize: 12.5, height: 1.3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Stars reward animation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: i < widget.stars ? 1.0 : 0.45,
                    ),
                    duration: Duration(milliseconds: 400 + i * 170),
                    curve: Curves.elasticOut,
                    builder: (_, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Icon(
                      i < widget.stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.gold,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onContinue,
              child: const Text(AppStrings.continueText),
            ),
          ),
        ],
      ),
    );
  }
}
