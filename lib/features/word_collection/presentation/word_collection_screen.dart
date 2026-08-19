import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/player_progress.dart';
import '../../../data/models/word_content.dart';
import '../../../data/repositories/word_repository.dart';
import '../../../shared/widgets/space_background.dart';
import '../../../core/services/audio_service.dart';
import 'widgets/word_card.dart';

class WordCollectionScreen extends StatefulWidget {
  const WordCollectionScreen({
    super.key,
    required this.wordRepository,
    required this.progress,
  });

  final WordRepository wordRepository;
  final PlayerProgress progress;

  @override
  State<WordCollectionScreen> createState() => _WordCollectionScreenState();
}

class _WordCollectionScreenState extends State<WordCollectionScreen> {
  String _selectedCategory = 'All';
  List<WordContent> _words = <WordContent>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await widget.wordRepository.getAllWords();
    if (mounted) {
      setState(() {
        _words = words;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SpaceBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.cyan),
          ),
        ),
      );
    }

    final categories = ['All', ...widget.wordRepository.getCategories(_words)];

    final filteredWords = _selectedCategory == 'All'
        ? _words
        : widget.wordRepository.getWordsByCategory(_words, _selectedCategory);

    final unlockedCount =
        filteredWords.where((w) => widget.progress.isWordUnlocked(w.id)).length;

    return Scaffold(
      body: SpaceBackground(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: AudioService.withSound(() => Navigator.pop(context)),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MY WORD COLLECTION',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'DISCOVERED ($unlockedCount / ${filteredWords.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.menu_book_rounded, color: AppColors.gold),
                ],
              ),
            ),

            // Category Filter Chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                      selectedColor: AppColors.cyan.withValues(alpha: 0.2),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.cyan : Colors.white70,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.cyan : Colors.white12,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Grid of Words
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
                itemCount: filteredWords.length,
                itemBuilder: (context, index) {
                  final word = filteredWords[index];
                  final isUnlocked = widget.progress.isWordUnlocked(word.id);

                  return WordCard(
                    word: word,
                    isUnlocked: isUnlocked,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
