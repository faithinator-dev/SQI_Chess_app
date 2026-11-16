class PracticeAchievement {
  const PracticeAchievement({required this.id, required this.title, required this.description, required this.emoji});

  final String id;
  final String title;
  final String description;
  final String emoji;
}

const practiceAchievements = <PracticeAchievement>[
  PracticeAchievement(id: 'first_move', title: 'First Steps', description: 'Make your first move against the computer.', emoji: '♟️'),
  PracticeAchievement(id: 'first_game', title: 'Game On', description: 'Finish your first computer game.', emoji: '🎮'),
  PracticeAchievement(id: 'first_win', title: 'First Victory', description: 'Win your first game against the computer.', emoji: '🏆'),
  PracticeAchievement(id: 'first_black', title: 'Night Rider', description: 'Play a computer game as Black.', emoji: '♟️'),
  PracticeAchievement(id: 'first_random', title: 'Roll the Dice', description: 'Start a game with Play Random.', emoji: '🎲'),
  PracticeAchievement(id: 'ten_moves', title: 'Getting into Rhythm', description: 'Make 10 moves in one game.', emoji: '🎵'),
  PracticeAchievement(id: 'twenty_moves', title: 'Long Game', description: 'Make 20 moves in one game.', emoji: '⏳'),
  PracticeAchievement(id: 'fifty_moves', title: 'Marathon Match', description: 'Make 50 moves in one game.', emoji: '🏃'),
  PracticeAchievement(id: 'five_games', title: 'Regular Player', description: 'Finish 5 computer games.', emoji: '📅'),
  PracticeAchievement(id: 'ten_games', title: 'Dedicated Player', description: 'Finish 10 computer games.', emoji: '🔥'),
  PracticeAchievement(id: 'three_wins', title: 'Winning Habit', description: 'Win 3 computer games.', emoji: '🥇'),
  PracticeAchievement(id: 'five_wins', title: 'On a Roll', description: 'Win 5 computer games.', emoji: '🚀'),
  PracticeAchievement(id: 'creator_win', title: 'Creator Conqueror', description: 'Beat the Creator difficulty computer.', emoji: '👑'),
  PracticeAchievement(id: 'checkmate', title: 'Checkmate!', description: 'Deliver checkmate to the computer.', emoji: '♛'),
  PracticeAchievement(id: 'win_as_black', title: 'Black Triumph', description: 'Win a computer game as Black.', emoji: '⚫'),
];
