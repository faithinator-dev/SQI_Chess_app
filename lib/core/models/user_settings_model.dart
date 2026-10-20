class UserSettingsModel {
  const UserSettingsModel({
    required this.userId,
    this.notifications = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.matchInvites = true,
    this.communityMentions = true,
    this.gameSounds = true,
    this.vibration = true,
    this.boardCoordinates = true,
    this.confirmResignation = true,
    this.reduceMotion = false,
    this.appearance = 'Dark',
    this.language = 'English',
    this.timezone = 'Africa/Lagos',
  });

  final String userId;

  final bool notifications;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool matchInvites;
  final bool communityMentions;

  final bool gameSounds;
  final bool vibration;
  final bool boardCoordinates;
  final bool confirmResignation;

  final bool reduceMotion;

  final String appearance;
  final String language;
  final String timezone;

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      userId: map['user_id'] as String,
      notifications: map['notifications'] as bool? ?? true,
      emailNotifications: map['email_notifications'] as bool? ?? true,
      pushNotifications: map['push_notifications'] as bool? ?? true,
      matchInvites: map['match_invites'] as bool? ?? true,
      communityMentions: map['community_mentions'] as bool? ?? true,
      gameSounds: map['game_sounds'] as bool? ?? true,
      vibration: map['vibration'] as bool? ?? true,
      boardCoordinates: map['board_coordinates'] as bool? ?? true,
      confirmResignation: map['confirm_resignation'] as bool? ?? true,
      reduceMotion: map['reduce_motion'] as bool? ?? false,
      appearance: map['appearance'] as String? ?? 'Dark',
      language: map['language'] as String? ?? 'English',
      timezone: map['timezone'] as String? ?? 'Africa/Lagos',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'notifications': notifications,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'match_invites': matchInvites,
      'community_mentions': communityMentions,
      'game_sounds': gameSounds,
      'vibration': vibration,
      'board_coordinates': boardCoordinates,
      'confirm_resignation': confirmResignation,
      'reduce_motion': reduceMotion,
      'appearance': appearance,
      'language': language,
      'timezone': timezone,
    };
  }

  UserSettingsModel copyWith({
    bool? notifications,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? matchInvites,
    bool? communityMentions,
    bool? gameSounds,
    bool? vibration,
    bool? boardCoordinates,
    bool? confirmResignation,
    bool? reduceMotion,
    String? appearance,
    String? language,
    String? timezone,
  }) {
    return UserSettingsModel(
      userId: userId,
      notifications: notifications ?? this.notifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      matchInvites: matchInvites ?? this.matchInvites,
      communityMentions: communityMentions ?? this.communityMentions,
      gameSounds: gameSounds ?? this.gameSounds,
      vibration: vibration ?? this.vibration,
      boardCoordinates: boardCoordinates ?? this.boardCoordinates,
      confirmResignation: confirmResignation ?? this.confirmResignation,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      appearance: appearance ?? this.appearance,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
    );
  }
}
