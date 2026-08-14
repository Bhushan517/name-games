import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../data/models/word_content.dart';

class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.isUnlocked,
  });

  final WordContent word;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? AppColors.cyan.withValues(alpha: 0.4)
              : Colors.white12,
        ),
      ),
      child: isUnlocked ? _buildUnlockedContent() : _buildLockedContent(),
    );
  }

  Widget _buildLockedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, size: 36, color: Colors.white24),
        const SizedBox(height: 8),
        Text(
          '???',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white24,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          word.category,
          style: TextStyle(fontSize: 10, color: Colors.white24),
        ),
      ],
    );
  }

  Widget _buildUnlockedContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(word.emoji, style: const TextStyle(fontSize: 26)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => TtsService.speak(
                  word.pronunciation.isNotEmpty
                      ? word.pronunciation
                      : word.word,
                ),
                icon: const Icon(
                  Icons.volume_up_rounded,
                  size: 20,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            word.word,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              word.category.toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: AppColors.cyan,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            word.meaningEnglish,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'मराठी: ${word.meaningMarathi}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, color: AppColors.gold),
          ),
          const SizedBox(height: 2),
          Text(
            'हिन्दी: ${word.meaningHindi}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 9.5, color: AppColors.emeraldGreen),
          ),
        ],
      ),
    );
  }
}
