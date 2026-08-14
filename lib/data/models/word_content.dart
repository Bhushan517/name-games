class WordContent {
  const WordContent({
    required this.id,
    required this.word,
    required this.category,
    required this.emoji,
    required this.sentenceClue,
    required this.meaningEnglish,
    required this.meaningMarathi,
    required this.meaningHindi,
    required this.pronunciation,
    required this.difficulty,
    required this.patternTemplate,
    required this.minimumAge,
  });

  final String id;
  final String word;
  final String category;
  final String emoji;
  final String sentenceClue;
  final String meaningEnglish;
  final String meaningMarathi;
  final String meaningHindi;
  final String pronunciation;
  final String difficulty;
  final String patternTemplate;
  final int minimumAge;

  int get letterCount => word.length;

  factory WordContent.fromJson(Map<String, dynamic> json) {
    return WordContent(
      id: json['id'] as String,
      word: (json['word'] as String).toUpperCase().trim(),
      category: json['category'] as String,
      emoji: json['emoji'] as String,
      sentenceClue: json['sentenceClue'] as String,
      meaningEnglish: json['meaningEnglish'] as String,
      meaningMarathi: json['meaningMarathi'] as String,
      meaningHindi: json['meaningHindi'] as String,
      pronunciation: json['pronunciation'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'easy',
      patternTemplate: json['patternTemplate'] as String? ?? 'star',
      minimumAge: (json['minimumAge'] as num?)?.toInt() ?? 7,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'category': category,
        'emoji': emoji,
        'sentenceClue': sentenceClue,
        'meaningEnglish': meaningEnglish,
        'meaningMarathi': meaningMarathi,
        'meaningHindi': meaningHindi,
        'pronunciation': pronunciation,
        'difficulty': difficulty,
        'patternTemplate': patternTemplate,
        'minimumAge': minimumAge,
      };
}
