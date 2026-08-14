import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/word_level.dart';

class LevelCompleteDialog extends StatefulWidget {
  const LevelCompleteDialog({
    super.key,
    required this.level,
    required this.stars,
    required this.onContinue,
  });

  final WordLevel level;
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
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _animController,
        curve: Curves.elasticOut,
      ),
      child: AlertDialog(
        title: const Text(
          AppStrings.brilliant,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.level.emoji, style: const TextStyle(fontSize: 54)),
            const SizedBox(height: 4),
            Text(
              widget.level.word,
              style: TextStyle(
                color: widget.level.color,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.level.meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
            const SizedBox(height: 14),
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
                    size: 38,
                  ),
                ),
              ),
            ),
          ],
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
