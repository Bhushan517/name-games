import '../models/word_content.dart';
import '../sources/local_word_data_source.dart';

class WordRepository {
  WordRepository(this._dataSource);

  final LocalWordDataSource _dataSource;

  Future<List<WordContent>> getAllWords() async {
    return _dataSource.loadWords();
  }

  List<WordContent> getCachedWords() {
    return _dataSource.getCachedWords();
  }

  List<String> getCategories(List<WordContent> words) {
    return words.map((w) => w.category).toSet().toList()..sort();
  }

  List<WordContent> getWordsByCategory(
    List<WordContent> words,
    String category,
  ) {
    return words
        .where((w) => w.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  WordContent? findWordById(List<WordContent> words, String id) {
    try {
      return words.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }
}
