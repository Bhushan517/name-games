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
    this.isDailyMode = false,
    Random? random,
  }) : _random = random ?? Random() {
    _initGame();
  }

  final GeneratedChallenge challenge;
  final ChallengeRepository repository;

  /// When true, completing the challenge does NOT call [repository.saveChallengeCompletion].
  /// This prevents Daily Quest completions from unlocking or skipping campaign levels.
  final bool isDailyMode;

  final Random _random;

  late List<LetterNode> _nodes;
  final List<int> _selectedIndices = <int>[];
  late int _lives;
  final Set<int> _revealedHintIndices = <int>{};
  bool _freeHintUsedForScoring = false;
  int _rewardedLivesUsed = 0;
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
  Set<int> get revealedHintIndices => Set.unmodifiable(_revealedHintIndices);
  int get lives => _lives;
  bool get isNextHintFree => _revealedHintIndices.isEmpty;
  bool get canUseHint =>
      _revealedHintIndices.length < (letterCount - 1) && !_isCompleted;
  int get totalHintsUsed => _revealedHintIndices.length;
  int get maxHints => letterCount - 1;
  int get rewardedLivesUsed => _rewardedLivesUsed;
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
    _freeHintUsedForScoring = true; // small penalty for replay
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
  /// Speaks the actual English word aloud (e.g. "EAGLE") so the child hears
  /// a clear, natural pronunciation — not the hyphenated phonetic string.
  Future<void> speakWordOrClue() async {
    HapticService.tap();
    await TtsService.speak(challenge.word);
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

  void grantHint() {
    if (!canUseHint) return;

    if (mode == ChallengeMode.missingLetter) {
      for (final idx in _missingIndices) {
        if (_filledMissingLetters[idx] != word[idx]) {
          _filledMissingLetters[idx] = word[idx];
          _revealedHintIndices.add(idx);
          break;
        }
      }
    } else {
      int indexToReveal = -1;
      for (int i = 0; i < word.length; i++) {
        if (i < _selectedIndices.length) {
          if (_nodes[_selectedIndices[i]].letter != word[i]) {
            indexToReveal = i;
            break;
          }
        } else {
          indexToReveal = i;
          break;
        }
      }

      if (indexToReveal != -1) {
        _revealedHintIndices.add(indexToReveal);

        if (_selectedIndices.length > indexToReveal) {
          _selectedIndices.removeRange(indexToReveal, _selectedIndices.length);
        }

        int nodeIndexInNodes = -1;
        for (int i = 0; i < _nodes.length; i++) {
          if (_nodes[i].letter == word[indexToReveal] &&
              !_selectedIndices.contains(i)) {
            nodeIndexInNodes = i;
            break;
          }
        }

        if (nodeIndexInNodes != -1) {
          _selectedIndices.add(nodeIndexInNodes);
        }
      }
    }

    if (_revealedHintIndices.length == 1) {
      _freeHintUsedForScoring = true;
    }

    _validationState = GameValidationState.initial;
    notifyListeners();
  }

  bool get canUseRewardedLife => _rewardedLivesUsed < 2;

  void grantRewardedLife() {
    if (canUseRewardedLife) {
      _rewardedLivesUsed++;
      _lives++;

      // Clear out of lives state
      if (_validationState == GameValidationState.outOfLives) {
        _validationState = GameValidationState.initial;
      }

      // For Timed mode, ensure timer restarts if it was cancelled
      if (mode == ChallengeMode.timed) {
        if (_timedChallengeTimer == null || !_timedChallengeTimer!.isActive) {
          _startTimedMode();
        } else {
          resumeTimer();
        }
      }

      notifyListeners();
    }
  }

  int calculateStars() {
    if (_freeHintUsedForScoring) return 2;
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
      // Daily mode must never unlock or skip campaign challenge numbers.
      if (!isDailyMode) {
        await repository.saveChallengeCompletion(
          challenge: challenge,
          starsEarned: stars,
        );
      }
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
    _revealedHintIndices.clear();
    _freeHintUsedForScoring = false;
    _rewardedLivesUsed = 0;
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
