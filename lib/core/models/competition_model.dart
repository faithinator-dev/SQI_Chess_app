class CompetitionModel {
  const CompetitionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.format,
    required this.timeControl,
    required this.rated,
    this.capacity,
    this.registrationDeadline,
    this.startsAt,
    this.endsAt,
    this.registered = false,
    this.registeredPlayers = 0,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String format;
  final String timeControl;
  final bool rated;
  final int? capacity;
  final DateTime? registrationDeadline;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool registered;
  final int registeredPlayers;

  factory CompetitionModel.fromMap(
    Map<String, dynamic> map, {
    bool registered = false,
    int registeredPlayers = 0,
  }) {
    DateTime? dateValue(dynamic value) {
      if (value is! String || value.isEmpty) return null;
      return DateTime.tryParse(value)?.toLocal();
    }

    return CompetitionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      status: map['status'] as String,
      format: map['format'] as String,
      timeControl: map['time_control'] as String,
      rated: map['rated'] as bool? ?? false,
      capacity: (map['capacity'] as num?)?.toInt(),
      registrationDeadline: dateValue(map['registration_deadline']),
      startsAt: dateValue(map['starts_at']),
      endsAt: dateValue(map['ends_at']),
      registered: registered,
      registeredPlayers: registeredPlayers,
    );
  }
}
