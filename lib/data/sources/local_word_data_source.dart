import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/word_content.dart';

class LocalWordDataSource {
  List<WordContent>? _cachedWords;

  Future<List<WordContent>> loadWords() async {
    if (_cachedWords != null && _cachedWords!.isNotEmpty) {
      return _cachedWords!;
    }

    String jsonString;
    try {
      jsonString = await rootBundle.loadString('assets/data/word_levels.json');
    } catch (_) {
      final file = File('assets/data/word_levels.json');
      if (file.existsSync()) {
        jsonString = file.readAsStringSync();
      } else {
        rethrow;
      }
    }

    final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;

    _cachedWords = decoded
        .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
        .toList();

    return _cachedWords!;
  }

  List<WordContent> getCachedWords() {
    return _cachedWords ?? <WordContent>[];
  }
}
