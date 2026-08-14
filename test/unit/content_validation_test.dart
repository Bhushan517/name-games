import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/data/models/word_content.dart';

void main() {
  group('100 Curated Words Content Validation Tests', () {
    late List<WordContent> words;

    setUpAll(() {
      final file = File('assets/data/word_levels.json');
      expect(file.existsSync(), isTrue,
          reason: 'word_levels.json must exist in assets/data/');
      final jsonString = file.readAsStringSync();
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      words = decoded
          .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    test('Contains exactly 100 unique curated words', () {
      expect(words.length, 100);

      final uniqueWords = words.map((w) => w.word).toSet();
      expect(uniqueWords.length, 100, reason: 'Every word must be unique');

      final uniqueIds = words.map((w) => w.id).toSet();
      expect(uniqueIds.length, 100, reason: 'Every ID must be unique');
    });

    test('Contains exactly 10 categories with 10 words each', () {
      final categories = words.map((w) => w.category).toSet();
      expect(categories.length, 10,
          reason: 'There must be exactly 10 categories');

      final expectedCategories = [
        'Animals',
        'Nature',
        'Home',
        'School',
        'Food',
        'Body and Health',
        'Space and Science',
        'Action Words',
        'Places and Transport',
        'Feelings and Values',
      ];

      for (final cat in expectedCategories) {
        final count = words.where((w) => w.category == cat).length;
        expect(count, 10,
            reason: 'Category "$cat" must contain exactly 10 words');
      }
    });

    test('All words satisfy length, character, and metadata constraints', () {
      final validDifficulties = {'easy', 'medium', 'hard'};
      final validTemplates = {
        'diamond',
        'square',
        'kite',
        'star',
        'house',
        'crown',
        'heart',
        'tree',
        'hexagon',
        'lightning',
        'rocket',
        'spiral',
        'mountain',
        'wave',
        'flower',
        'octagon',
        'butterfly',
      };

      for (final word in words) {
        // Length check (4 to 8 letters)
        expect(word.letterCount, inInclusiveRange(4, 8),
            reason: 'Word "${word.word}" must be between 4 and 8 letters');

        // Alphabetic only
        expect(RegExp(r'^[A-Z]+$').hasMatch(word.word), isTrue,
            reason: 'Word "${word.word}" must contain only uppercase letters');

        // Non-empty fields
        expect(word.sentenceClue.isNotEmpty, isTrue);
        expect(word.meaningEnglish.isNotEmpty, isTrue);
        expect(word.meaningMarathi.isNotEmpty, isTrue);
        expect(word.meaningHindi.isNotEmpty, isTrue);
        expect(word.emoji.isNotEmpty, isTrue);

        // Clue blank placeholder check
        expect(word.sentenceClue.contains('_____'), isTrue,
            reason: 'Clue for "${word.word}" must contain blank "_____"');

        // Valid difficulty
        expect(validDifficulties.contains(word.difficulty), isTrue,
            reason: 'Invalid difficulty "${word.difficulty}" for ${word.word}');

        // Valid pattern template
        expect(validTemplates.contains(word.patternTemplate), isTrue,
            reason:
                'Invalid pattern template "${word.patternTemplate}" for ${word.word}');

        // Minimum age
        expect(word.minimumAge, inInclusiveRange(7, 13));
      }
    });
  });
}
