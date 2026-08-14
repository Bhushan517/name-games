import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';

class GameActionButtons extends StatelessWidget {
  const GameActionButtons({
    super.key,
    required this.onUndo,
    required this.onCheckWord,
  });

  final VoidCallback onUndo;
  final VoidCallback onCheckWord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onUndo,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text(AppStrings.undo),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: onCheckWord,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text(
                AppStrings.checkWord,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
