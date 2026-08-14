enum ChallengeMode {
  unscramble,
  missingLetter,
  listenSpell,
  memory,
  timed;

  String get displayName {
    switch (this) {
      case ChallengeMode.unscramble:
        return 'Unscramble & Draw';
      case ChallengeMode.missingLetter:
        return 'Missing Letter';
      case ChallengeMode.listenSpell:
        return 'Listen & Spell';
      case ChallengeMode.memory:
        return 'Memory Letters';
      case ChallengeMode.timed:
        return 'Timed Challenge';
    }
  }

  String get shortName {
    switch (this) {
      case ChallengeMode.unscramble:
        return 'UNSCRAMBLE';
      case ChallengeMode.missingLetter:
        return 'MISSING LETTER';
      case ChallengeMode.listenSpell:
        return 'LISTEN & SPELL';
      case ChallengeMode.memory:
        return 'MEMORY';
      case ChallengeMode.timed:
        return 'TIMED';
    }
  }

  String get idSuffix {
    switch (this) {
      case ChallengeMode.unscramble:
        return 'unscramble';
      case ChallengeMode.missingLetter:
        return 'missing_letter';
      case ChallengeMode.listenSpell:
        return 'listen_spell';
      case ChallengeMode.memory:
        return 'memory';
      case ChallengeMode.timed:
        return 'timed';
    }
  }

  static ChallengeMode fromSuffix(String suffix) {
    switch (suffix) {
      case 'missing_letter':
        return ChallengeMode.missingLetter;
      case 'listen_spell':
        return ChallengeMode.listenSpell;
      case 'memory':
        return ChallengeMode.memory;
      case 'timed':
        return ChallengeMode.timed;
      case 'unscramble':
      default:
        return ChallengeMode.unscramble;
    }
  }
}
