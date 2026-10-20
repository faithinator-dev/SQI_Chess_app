enum BotDifficulty { beginner, intermediate, advanced, expert, creator }

extension BotDifficultyExtension on BotDifficulty {
  String get title {
    switch (this) {
      case BotDifficulty.beginner:
        return 'Beginner';
      case BotDifficulty.intermediate:
        return 'Intermediate';
      case BotDifficulty.advanced:
        return 'Advanced';
      case BotDifficulty.expert:
        return 'Expert';
      case BotDifficulty.creator:
        return 'Faith Tolu';
    }
  }

  String get description {
    switch (this) {
      case BotDifficulty.beginner:
        return 'A relaxed opponent for learning the basics.';
      case BotDifficulty.intermediate:
        return 'A balanced opponent for improving your game.';
      case BotDifficulty.advanced:
        return 'A challenging opponent for stronger players.';
      case BotDifficulty.expert:
        return 'A powerful opponent for serious practice.';
      case BotDifficulty.creator:
        return 'Challenge faith tolu the Creator.';
    }
  }

  int get skillLevel {
    switch (this) {
      case BotDifficulty.beginner:
        return 2;
      case BotDifficulty.intermediate:
        return 8;
      case BotDifficulty.advanced:
        return 16;
      case BotDifficulty.expert:
        return 20;
      case BotDifficulty.creator:
        return 19;
    }
  }

  int get searchDepth {
    switch (this) {
      case BotDifficulty.beginner:
        return 5;
      case BotDifficulty.intermediate:
        return 10;
      case BotDifficulty.advanced:
        return 15;
      case BotDifficulty.expert:
        return 20;
      case BotDifficulty.creator:
        return 19;
    }
  }

  int get moveTimeMs {
    switch (this) {
      case BotDifficulty.beginner:
        return 150;
      case BotDifficulty.intermediate:
        return 300;
      case BotDifficulty.advanced:
        return 500;
      case BotDifficulty.expert:
        return 800;
      case BotDifficulty.creator:
        return 1200;
    }
  }

  int get elo {
    switch (this) {
      case BotDifficulty.beginner:
        return 800;
      case BotDifficulty.intermediate:
        return 1200;
      case BotDifficulty.advanced:
        return 1600;
      case BotDifficulty.expert:
        return 2000;
      case BotDifficulty.creator:
        return 1300;
    }
  }
}
