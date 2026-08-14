import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../data/models/challenge_mode.dart';
import '../../../data/models/generated_challenge.dart';
import '../../../data/models/letter_node.dart';
import '../../../data/repositories/challenge_repository.dart';

enum GameValidationState {
  initial,
  incomplete,
  correct,
  wrong,
  timeOut,
  outOfLives,
}

class GameController extends ChangeNotifier {
  GameController({
    required this.challenge,
    required this.repository,
    Random? random,
  }) : _random = random ?? Random() {
    _initGame();
  }

  final GeneratedChallenge challenge;
  final ChallengeRepository repository;
  final Random _random;

  late List<LetterNode> _nodes;
  final List<int> _selectedIndices = <int>[];
  late int _lives;
  bool _hintUsed = false;
  bool _isCompleted = false;
  GameValidationState _validationState = GameValidationState.initial;

  // --- Missing Letter Mode State ---
  final List<int> _missingIndices = <int>[];
  final List<String> _missingLetterChoices = <String>[];
  final Map<int, String> _filledMissingLetters = <int, String>{};

  // --- Memory Mode State ---
  bool _isMemoryRevealed = true;
  int _memorySecondsLeft = 0;
  Timer? _memoryTimer;

  // --- Timed Mode State ---
  int _timeRemaining = 0;
  Timer? _timedChallengeTimer;
  bool _isTimerPaused = false;

  // --- Getters ---
  List<LetterNode> get nodes => List.unmodifiable(_nodes);
  List<int> get selectedIndices => List.unmodifiable(_selectedIndices);
  int get lives => _lives;
  bool get hintUsed => _hintUsed;
  bool get isCompleted => _isCompleted;
  GameValidationState get validationState => _validationState;

  ChallengeMode get mode => challenge.mode;
  String get word => challenge.word;
  int get letterCount => challenge.letterCount;

  // Missing Letter Getters
  List<int> get missingIndices => List.unmodifiable(_missingIndices);
  List<String> get missingLetterChoices =>
      List.unmodifiable(_missingLetterChoices);
  Map<int, String> get filledMissingLetters =>
      Map.unmodifiable(_filledMissingLetters);

  // Memory Getters
  bool get isMemoryRevealed => _isMemoryRevealed;
  int get memorySecondsLeft => _memorySecondsLeft;

  // Timed Getters
  int get timeRemaining => _timeRemaining;
  bool get isTimerPaused => _isTimerPaused;

  String get currentAttempt {
    if (mode == ChallengeMode.missingLetter) {
      final buffer = StringBuffer();
      for (var i = 0; i < word.length; i++) {
        if (_missingIndices.contains(i)) {
          buffer.write(_filledMissingLetters[i] ?? '_');
        } else {
          buffer.write(word[i]);
        }
      }
      return buffer.toString();
    }
    return _selectedIndices.map((i) => _nodes[i].letter).join();
  }

  bool isSelected(int nodeIndex) => _selectedIndices.contains(nodeIndex);

  void _initGame() {
    _lives = challenge.difficultyConfig.lives;
    _initializeNodes();

    if (mode == ChallengeMode.missingLetter) {
      _initMissingLetterMode();
    } else if (mode == ChallengeMode.memory) {
      _startMemoryPreview();
    } else if (mode == ChallengeMode.timed) {
      _startTimedMode();
    }
  }

  void _initializeNodes() {
    final points = challenge.patternTemplate.points;
    _nodes = List.generate(
      letterCount,
      (i) => LetterNode(
        id: i,
        letter: word[i],
        position: points[i % points.length],
      ),
    )..shuffle(_random);
  }

  // --- Missing Letter Mode Setup ---
  void _initMissingLetterMode() {
    _missingIndices.clear();
    _filledMissingLetters.clear();
    _missingLetterChoices.clear();

    final countToHide = min(
      challenge.difficultyConfig.missingLetterCount,
      word.length - 1,
    );

    final availablePositions = List.generate(word.length, (i) => i)
      ..shuffle(_random);
    for (var i = 0; i < countToHide; i++) {
      _missingIndices.add(availablePositions[i]);
    }
    _missingIndices.sort();

    // Generate choices: correct letters + believable distractors
    final correctLetters = _missingIndices.map((idx) => word[idx]).toSet();
    final choices = Set<String>.from(correctLetters);

    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    while (choices.length < min(6, correctLetters.length + 3)) {
      final randomChar = alphabet[_random.nextInt(alphabet.length)];
      choices.add(randomChar);
    }

    _missingLetterChoices.addAll(choices.toList()..shuffle(_random));
  }

  void fillMissingLetter(String letter) {
    if (_isCompleted) return;
    HapticService.tap();
    for (final idx in _missingIndices) {
      if (!_filledMissingLetters.containsKey(idx)) {
        _filledMissingLetters[idx] = letter;
        break;
      }
    }
    _validationState = GameValidationState.initial;
    notifyListeners();
  }

  void clearLastMissingLetter() {
    if (_isCompleted || _filledMissingLetters.isEmpty) return;
    final keys = _filledMissingLetters.keys.toList()..sort();
    _filledMissingLetters.remove(keys.last);
    _validationState = GameValidationState.initial;
    notifyListeners();
  }

  // --- Memory Mode Setup ---
  void _startMemoryPreview() {
    _isMemoryRevealed = true;
    _memorySecondsLeft = challenge.difficultyConfig.memoryPreviewSeconds;
    _memoryTimer?.cancel();

    _memoryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _memorySecondsLeft--;
      if (_memorySecondsLeft <= 0) {
        timer.cancel();
        _isMemoryRevealed = false;
      }
      notifyListeners();
    });
  }

  void replayMemoryPreview() {
    if (_isCompleted) return;
    _hintUsed = true; // small penalty for replay
    _selectedIndices.clear();
    _startMemoryPreview();
    notifyListeners();
  }

  // --- Timed Mode Setup ---
  void _startTimedMode() {
    _timeRemaining = challenge.difficultyConfig.timerSeconds;
    _timedChallengeTimer?.cancel();

    _timedChallengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimerPaused) return;

      _timeRemaining--;
      if (_timeRemaining <= 0) {
        timer.cancel();
        _handleTimeout();
      }
      notifyListeners();
    });
  }

  void pauseTimer() {
    _isTimerPaused = true;
  }

  void resumeTimer() {
    _isTimerPaused = false;
  }

  void _handleTimeout() {
    if (_isCompleted) return;
    HapticService.error();
    _lives--;
    _selectedIndices.clear();
    if (_lives <= 0) {
      _validationState = GameValidationState.outOfLives;
    } else {
      _validationState = GameValidationState.timeOut;
      _timeRemaining = challenge.difficultyConfig.timerSeconds;
      _startTimedMode();
    }
    notifyListeners();
  }

  // --- TTS Speak ---
  Future<void> speakWordOrClue() async {
    HapticService.tap();
    await TtsService.speak(challenge.wordContent.pronunciation.isNotEmpty
        ? challenge.wordContent.pronunciation
        : challenge.wordContent.sentenceClue);
  }

  // --- User Selection Actions ---
  void selectLetter(int nodeIndex) {
    if (_isCompleted || isSelected(nodeIndex)) return;
    HapticService.tap();
    _selectedIndices.add(nodeIndex);
    _validationState = GameValidationState.initial;
    notifyListeners();
  }

  void undo() {
    if (mode == ChallengeMode.missingLetter) {
      clearLastMissingLetter();
      return;
    }
    if (_selectedIndices.isNotEmpty && !_isCompleted) {
      _selectedIndices.removeLast();
      _validationState = GameValidationState.initial;
      notifyListeners();
    }
  }

  void useHint() {
    if (!_hintUsed && challenge.difficultyConfig.allowFirstLetterHint) {
      _hintUsed = true;
      notifyListeners();
    }
  }

  int calculateStars() {
    if (_hintUsed) return 2;
    if (_lives == challenge.difficultyConfig.lives) return 3;
    return 2;
  }

  Future<GameValidationState> validateSpelling() async {
    if (mode == ChallengeMode.missingLetter) {
      if (_filledMissingLetters.length < _missingIndices.length) {
        _validationState = GameValidationState.incomplete;
        notifyListeners();
        return _validationState;
      }
    } else {
      if (_selectedIndices.length < letterCount) {
        _validationState = GameValidationState.incomplete;
        notifyListeners();
        return _validationState;
      }
    }

    if (currentAttempt == word) {
      _isCompleted = true;
      _memoryTimer?.cancel();
      _timedChallengeTimer?.cancel();
      _validationState = GameValidationState.correct;
      HapticService.success();
      final stars = calculateStars();
      await repository.saveChallengeCompletion(
        challenge: challenge,
        starsEarned: stars,
      );
      notifyListeners();
      return _validationState;
    }

    // Wrong spelling
    HapticService.error();
    _lives--;

    if (mode == ChallengeMode.missingLetter) {
      _filledMissingLetters.clear();
    } else {
      _selectedIndices.clear();
      _nodes.shuffle(_random);
    }

    if (_lives <= 0) {
      _validationState = GameValidationState.outOfLives;
    } else {
      _validationState = GameValidationState.wrong;
    }

    notifyListeners();
    return _validationState;
  }

  void resetLives() {
    _lives = challenge.difficultyConfig.lives;
    _selectedIndices.clear();
    _filledMissingLetters.clear();
    _validationState = GameValidationState.initial;
    if (mode == ChallengeMode.timed) {
      _startTimedMode();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _memoryTimer?.cancel();
    _timedChallengeTimer?.cancel();
    TtsService.stop();
    super.dispose();
  }
}
