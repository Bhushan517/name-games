import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/haptic_service.dart';
import '../../../data/models/letter_node.dart';
import '../../../data/models/word_level.dart';
import '../../../data/repositories/level_repository.dart';

enum GameValidationState {
  initial,
  incomplete,
  correct,
  wrong,
  outOfLives,
}

class GameController extends ChangeNotifier {
  GameController({
    required this.level,
    required this.repository,
    Random? random,
  }) : _random = random ?? Random() {
    _initializeNodes();
  }

  final WordLevel level;
  final LevelRepository repository;
  final Random _random;

  late List<LetterNode> _nodes;
  final List<int> _selectedIndices = <int>[];
  int _lives = AppConstants.maxLives;
  bool _hintUsed = false;
  bool _isCompleted = false;
  GameValidationState _validationState = GameValidationState.initial;

  List<LetterNode> get nodes => List.unmodifiable(_nodes);
  List<int> get selectedIndices => List.unmodifiable(_selectedIndices);
  int get lives => _lives;
  bool get hintUsed => _hintUsed;
  bool get isCompleted => _isCompleted;
  GameValidationState get validationState => _validationState;

  String get currentAttempt =>
      _selectedIndices.map((i) => _nodes[i].letter).join();

  bool isSelected(int nodeIndex) => _selectedIndices.contains(nodeIndex);

  void _initializeNodes() {
    _nodes = List.generate(
      level.letterCount,
      (i) => LetterNode(
        id: i,
        letter: level.word[i],
        position: level.points[i],
      ),
    )..shuffle(_random);
  }

  void selectLetter(int nodeIndex) {
    if (_isCompleted || isSelected(nodeIndex)) return;
    HapticService.tap();
    _selectedIndices.add(nodeIndex);
    _validationState = GameValidationState.initial;
    notifyListeners();
  }

  void undo() {
    if (_selectedIndices.isNotEmpty && !_isCompleted) {
      _selectedIndices.removeLast();
      _validationState = GameValidationState.initial;
      notifyListeners();
    }
  }

  void useHint() {
    if (!_hintUsed && _selectedIndices.isEmpty) {
      _hintUsed = true;
      notifyListeners();
    }
  }

  int calculateStars() {
    if (_hintUsed) return 2;
    return _lives == AppConstants.maxLives ? 3 : 2;
  }

  Future<GameValidationState> validateSpelling() async {
    if (_selectedIndices.length < level.letterCount) {
      _validationState = GameValidationState.incomplete;
      notifyListeners();
      return _validationState;
    }

    if (currentAttempt == level.word) {
      _isCompleted = true;
      _validationState = GameValidationState.correct;
      HapticService.success();
      final stars = calculateStars();
      await repository.saveLevelResult(level.index, stars);
      notifyListeners();
      return _validationState;
    }

    // Incorrect answer
    HapticService.error();
    _lives--;
    _selectedIndices.clear();
    _nodes.shuffle(_random);

    if (_lives <= 0) {
      _validationState = GameValidationState.outOfLives;
    } else {
      _validationState = GameValidationState.wrong;
    }

    notifyListeners();
    return _validationState;
  }

  void resetLives() {
    _lives = AppConstants.maxLives;
    _selectedIndices.clear();
    _validationState = GameValidationState.initial;
    notifyListeners();
  }
}
