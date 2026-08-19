import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';

class PackSelector extends StatelessWidget {
  const PackSelector({
    super.key,
    required this.selectedPack,
    required this.onPackSelected,
  });

  final int selectedPack; // 0 to 9
  final ValueChanged<int> onPackSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (context, index) {
          final isSelected = index == selectedPack;
          final startLevel = index * 50 + 1;
          final endLevel = (index + 1) * 50;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: AudioService.withSound(() => onPackSelected(index)),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.cyan.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.cyan : Colors.white12,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  'Pack ${index + 1} ($startLevel–$endLevel)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected ? AppColors.cyan : Colors.white70,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
