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
      height: 46,
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
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            AppColors.cyan,
                            AppColors.purple,
                          ],
                        )
                      : null,
                  color: isSelected ? null : const Color(0x1F16223D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.12),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.stars_rounded : Icons.folder_open_rounded,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pack ${index + 1} ($startLevel–$endLevel)',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.5,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),

                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
