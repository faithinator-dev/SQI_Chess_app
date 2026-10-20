class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.skillLevel,
    required this.chessRating,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.currentStreak,
    required this.sqiStatus,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.department,
    this.level,
    this.campus,
    this.preferredTimeControl,
    this.playStyle,
    this.publicProfile = true,
  });

  final String id;
  final String username;
  final String fullName;
  final String skillLevel;

  final int chessRating;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int currentStreak;

  final String sqiStatus;
  final String role;

  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? department;
  final String? level;
  final String? campus;
  final String? preferredTimeControl;
  final String? playStyle;

  final bool publicProfile;

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      username: (map['username'] as String?) ?? '',
      fullName: (map['full_name'] as String?) ?? 'SQI Player',
      skillLevel: (map['skill_level'] as String?) ?? 'Beginner',
      chessRating: _intValue(map['chess_rating'], 1000),
      gamesPlayed: _intValue(map['games_played'], 0),
      wins: _intValue(map['wins'], 0),
      losses: _intValue(map['losses'], 0),
      draws: _intValue(map['draws'], 0),
      currentStreak: _intValue(map['current_streak'], 0),
      sqiStatus: (map['sqi_status'] as String?) ?? 'Student',
      role: (map['role'] as String?) ?? 'player',
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      department: map['department'] as String?,
      level: map['level'] as String?,
      campus: map['campus'] as String?,
      preferredTimeControl: map['preferred_time_control'] as String?,
      playStyle: map['play_style'] as String?,
      publicProfile: map['public_profile'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'skill_level': skillLevel,
      'chess_rating': chessRating,
      'games_played': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'current_streak': currentStreak,
      'sqi_status': sqiStatus,
      'role': role,
      'phone': phone,
      'avatar_url': avatarUrl,
      'bio': bio,
      'department': department,
      'level': level,
      'campus': campus,
      'preferred_time_control': preferredTimeControl,
      'play_style': playStyle,
      'public_profile': publicProfile,
    };
  }

  double get winRate {
    if (gamesPlayed == 0) {
      return 0;
    }

    return wins / gamesPlayed;
  }

  String get formattedRating {
    return chessRating.toString();
  }

  String get initials {
    final cleaned = fullName.trim();

    if (cleaned.isEmpty) {
      return '?';
    }

    final parts = cleaned.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  bool get isAdmin => role == 'admin';

  static int _intValue(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return fallback;
  }
}
