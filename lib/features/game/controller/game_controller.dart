import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/services/audio_service.dart';
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
  final Map<int, int> _fixedHintNodeIdByPosition = {};
  final List<int> _manualSelectedNodeIds = <int>[];
  late int _lives;
  bool _freeHintUsedForScoring = false;
  int _rewardedLivesUsed = 0;
  bool _isCompleted = false;
  GameValidationState _validationState = GameValidationState.initial;

  // --- Missing Letter Mode State ---
  final List<int> _missingIndices = <int>[];
  final List<String> _missingLetterChoices = <String>[];
  final Map<int, String> _filledMissingLetters = <int, String>{};
  final Set<int> _hintedMissingIndices = <int>{};

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

  List<int?> get activeNodeIdsByPosition {
    final List<int?> result = List.filled(letterCount, null);

    // First, place fixed hints
    for (final entry in _fixedHintNodeIdByPosition.entries) {
      result[entry.key] = entry.value;
    }

    // Then, place manual selections into the FIRST AVAILABLE empty slots
    int manualIdx = 0;
    for (int i = 0; i < letterCount; i++) {
      if (result[i] == null && manualIdx < _manualSelectedNodeIds.length) {
        result[i] = _manualSelectedNodeIds[manualIdx];
        manualIdx++;
      }
    }

    return result;
  }

  List<int?> get selectedIndices => activeNodeIdsByPosition
      .map((id) => id != null ? _nodes.indexWhere((n) => n.id == id) : null)
      .toList();

  Set<int> get revealedHintIndices => mode == ChallengeMode.missingLetter
      ? Set.unmodifiable(_hintedMissingIndices)
      : Set.unmodifiable(_fixedHintNodeIdByPosition.keys);
  int get lives => _lives;
  bool get isNextHintFree => revealedHintIndices.isEmpty;

  bool get canUseHint {
    if (_isCompleted) return false;
    if (mode == ChallengeMode.missingLetter) {
      return _missingIndices.any((index) =>
          !_hintedMissingIndices.contains(index) &&
          _filledMissingLetters[index] != word[index]);
    }
    return _fixedHintNodeIdByPosition.length < (letterCount - 1);
  }

  int get totalHintsUsed => revealedHintIndices.length;
  int get maxHints {
    if (mode == ChallengeMode.missingLetter) {
      return _missingIndices.length;
    }
    return letterCount - 1;
  }

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
    return activeNodeIdsByPosition.map((id) {
      if (id == null) return '_';
      final node = _nodes.firstWhere((n) => n.id == id);
      return node.letter;
    }).join();
  }

  bool isSelected(int nodeIndex) {
    final id = _nodes[nodeIndex].id;
    return _fixedHintNodeIdByPosition.containsValue(id) ||
        _manualSelectedNodeIds.contains(id);
  }

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
    _hintedMissingIndices.clear();

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

    // Find the last filled index that is NOT a hinted fixed index
    final manualKeys = _filledMissingLetters.keys
        .where((k) => !_hintedMissingIndices.contains(k))
        .toList()
      ..sort();
    if (manualKeys.isNotEmpty) {
      AudioService().playSfx('letter_undo.wav');
      _filledMissingLetters.remove(manualKeys.last);
      _validationState = GameValidationState.initial;
      notifyListeners();
    }
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
    _manualSelectedNodeIds.clear();
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
      if (_timeRemaining <= 5 && _timeRemaining > 0) {
        AudioService().playSfx('timer_tick.wav', volume: 0.3);
      }
      
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
    _manualSelectedNodeIds.clear();
    if (_lives <= 0) {
      _validationState = GameValidationState.outOfLives;
      AudioService().playSfx('out_of_lives.wav', volume: 0.35);
    } else {
      _validationState = GameValidationState.timeOut;
      AudioService().playSfx('wrong_answer.wav', volume: 0.35);
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
    AudioService().playSfx('letter_select.wav');
    HapticService.tap();
    _manualSelectedNodeIds.add(_nodes[nodeIndex].id);
    _validationState = GameValidationState.initial;
    notifyListeners();
  }

  void undo() {
    if (mode == ChallengeMode.missingLetter) {
      clearLastMissingLetter();
      return;
    }
    if (_manualSelectedNodeIds.isNotEmpty && !_isCompleted) {
      AudioService().playSfx('letter_undo.wav');
      _manualSelectedNodeIds.removeLast();
      _validationState = GameValidationState.initial;
      notifyListeners();
    }
  }

  void grantHint() {
    if (!canUseHint) return;
    
    AudioService().playSfx('hint_reveal.wav');

    if (mode == ChallengeMode.missingLetter) {
      for (final idx in _missingIndices) {
        if (!_hintedMissingIndices.contains(idx) &&
            _filledMissingLetters[idx] != word[idx]) {
          _filledMissingLetters[idx] = word[idx];
          _hintedMissingIndices.add(idx);
          break;
        }
      }
    } else {
      int hintTargetIndex = -1;
      final currentActiveIds = activeNodeIdsByPosition;

      for (int i = 0; i < word.length; i++) {
        if (!_fixedHintNodeIdByPosition.containsKey(i)) {
          final idAtSlot = currentActiveIds[i];
          if (idAtSlot == null) {
            hintTargetIndex = i;
            break;
          } else {
            final node = _nodes.firstWhere((n) => n.id == idAtSlot);
            if (node.letter != word[i]) {
              hintTargetIndex = i;
              break;
            }
          }
        }
      }

      if (hintTargetIndex == -1) {
        hintTargetIndex = List.generate(word.length, (i) => i).firstWhere(
            (i) => !_fixedHintNodeIdByPosition.containsKey(i),
            orElse: () => -1);
      }

      if (hintTargetIndex != -1) {
        final expectedLetter = word[hintTargetIndex];
        final targetNode = _nodes.firstWhere((n) =>
            n.letter == expectedLetter &&
            !_fixedHintNodeIdByPosition.containsValue(n.id));

        _fixedHintNodeIdByPosition[hintTargetIndex] = targetNode.id;
        _manualSelectedNodeIds.remove(targetNode.id);
      }
    }

    if (revealedHintIndices.length == 1) {
      _freeHintUsedForScoring = true;
    }

    _validationState = GameValidationState.initial;
    notifyListeners();
  }

  bool get canUseRewardedLife => _rewardedLivesUsed < 2;

  void grantRewardedLife() {
    if (canUseRewardedLife) {
      AudioService().playSfx('extra_life.wav');
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
      if (activeNodeIdsByPosition.contains(null)) {
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
      AudioService().playSfx('correct_answer.wav');
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
      final manualKeys = _filledMissingLetters.keys
          .where((k) => !_hintedMissingIndices.contains(k))
          .toList();
      for (final key in manualKeys) {
        _filledMissingLetters.remove(key);
      }
    } else {
      _manualSelectedNodeIds.clear();
      _nodes.shuffle(_random);
    }

    if (_lives <= 0) {
      _validationState = GameValidationState.outOfLives;
      AudioService().playSfx('out_of_lives.wav', volume: 0.35);
    } else {
      _validationState = GameValidationState.wrong;
      AudioService().playSfx('wrong_answer.wav', volume: 0.35);
    }

    notifyListeners();
    return _validationState;
  }

  void resetLives() {
    _lives = challenge.difficultyConfig.lives;
    _fixedHintNodeIdByPosition.clear();
    _hintedMissingIndices.clear();
    _freeHintUsedForScoring = false;
    _rewardedLivesUsed = 0;
    _manualSelectedNodeIds.clear();
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
