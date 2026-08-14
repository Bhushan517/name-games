import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class TimerBar extends StatelessWidget {
  const TimerBar({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  final int secondsRemaining;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? secondsRemaining / totalSeconds : 0.0;
    final isUrgent = secondsRemaining <= 5;
    final barColor = isUrgent ? AppColors.pink : AppColors.cyan;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isUrgent ? AppColors.pink : Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'TIME REMAINING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: isUrgent ? AppColors.pink : Colors.white60,
                    ),
                  ),
                ],
              ),
              Text(
                '${secondsRemaining}s',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isUrgent ? AppColors.pink : AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              color: barColor,
              backgroundColor: Colors.white12,
            ),
          ),
        ],
      ),
    );
  }
}
