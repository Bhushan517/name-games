import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        AppStrings.howToPlay,
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RuleItem(
              icon: Icons.lightbulb_rounded,
              text:
                  'Read the category, clue sentence and emoji clue inside the level.',
            ),
            _RuleItem(
              icon: Icons.touch_app_rounded,
              text: 'Tap scrambled letters in the correct spelling order.',
            ),
            _RuleItem(
              icon: Icons.gesture_rounded,
              text:
                  'Check the word to reveal and animate the secret glowing shape.',
            ),
            _RuleItem(
              icon: Icons.favorite_rounded,
              text:
                  'A wrong word reduces one life. Keep all 3 lives for 3 stars!',
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.gotIt),
        ),
      ],
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyan, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
