import 'package:flutter/material.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../shared/widgets/space_background.dart';

class OnboardingSlide {
  const OnboardingSlide(this.icon, this.title, this.text, this.color);
  final IconData icon;
  final String title;
  final String text;
  final Color color;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.storageService});

  final LocalStorageService storageService;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = const [
    OnboardingSlide(
      Icons.shuffle_rounded,
      'UNSCRAMBLE WORDS',
      'Use the picture and sentence clue to discover a meaningful word.',
      AppColors.cyan,
    ),
    OnboardingSlide(
      Icons.auto_awesome_rounded,
      'REVEAL PATTERNS',
      'Tap letters in order. Every correct word reveals a magical hidden shape.',
      AppColors.purple,
    ),
    OnboardingSlide(
      Icons.school_rounded,
      'LEARN & WIN',
      'Improve spelling, learn meanings and collect three stars on every level.',
      AppColors.pink,
    ),
  ];

  Future<void> _finishOnboarding() async {
    await widget.storageService.setOnboardingSeen();
    if (mounted) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text(AppStrings.skip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, index) {
                  final slide = _slides[index];
                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey(index),
                            tween: Tween<double>(begin: 0.4, end: 1.0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.elasticOut,
                            builder: (_, value, child) =>
                                Transform.scale(scale: value, child: child),
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: slide.color.withValues(alpha: 0.12),
                                border:
                                    Border.all(color: slide.color, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: slide.color.withValues(alpha: 0.22),
                                    blurRadius: 50,
                                  ),
                                ],
                              ),
                              child: Icon(slide.icon,
                                  color: slide.color, size: 80),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            slide.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.all(4),
                        width: i == _currentPage ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? _slides[_currentPage].color
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _currentPage == _slides.length - 1
                          ? _finishOnboarding
                          : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 420),
                                curve: Curves.easeOutCubic,
                              ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? AppStrings.startQuest
                            : AppStrings.next,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
