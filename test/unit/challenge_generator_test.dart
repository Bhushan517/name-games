import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_twist_game/data/generators/challenge_generator.dart';
import 'package:name_twist_game/data/models/challenge_mode.dart';
import 'package:name_twist_game/data/models/word_content.dart';

void main() {
  group('500 Challenges Generation Tests', () {
    late List<WordContent> words;

    setUpAll(() {
      final file = File('assets/data/word_levels.json');
      final jsonString = file.readAsStringSync();
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      words = decoded
          .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    test('Generates exactly 500 deterministic challenges (100 words x 5 modes)',
        () {
      final challenges = ChallengeGenerator.generateAllChallenges(words);
      expect(challenges.length, 500);

      // Check unique challenge IDs
      final ids = challenges.map((c) => c.id).toSet();
      expect(ids.length, 500);

      // Check challenge numbers (1 to 500)
      for (var i = 0; i < challenges.length; i++) {
        expect(challenges[i].challengeNumber, i + 1);
      }

      // Check all 5 modes represented equally (100 per mode)
      for (final mode in ChallengeMode.values) {
        final modeCount = challenges.where((c) => c.mode == mode).length;
        expect(modeCount, 100);
      }

      // Re-running generation yields identical deterministic results
      final secondRun = ChallengeGenerator.generateAllChallenges(words);
      for (var i = 0; i < 500; i++) {
        expect(challenges[i].id, secondRun[i].id);
        expect(challenges[i].mode, secondRun[i].mode);
        expect(challenges[i].word, secondRun[i].word);
      }
    });

    test('10 Level Packs contain exactly 50 challenges each', () {
      final challenges = ChallengeGenerator.generateAllChallenges(words);

      for (var packIndex = 0; packIndex < 10; packIndex++) {
        final start = packIndex * 50;
        final end = (packIndex + 1) * 50;
        final packChallenges = challenges.sublist(start, end);
        expect(packChallenges.length, 50);
        expect(packChallenges.first.challengeNumber, start + 1);
        expect(packChallenges.last.challengeNumber, end);
      }
    });
  });
}
