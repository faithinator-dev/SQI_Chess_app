class AppReleaseModel {
  const AppReleaseModel({
    required this.id,
    required this.platform,
    required this.versionName,
    required this.buildNumber,
    required this.title,
    required this.purpose,
    required this.changes,
    required this.instructions,
    required this.downloadUrl,
    required this.isPublished,
    this.publishedAt,
  });

  final String id;
  final String platform;
  final String versionName;
  final int buildNumber;
  final String title;
  final String purpose;
  final List<String> changes;
  final String instructions;
  final String downloadUrl;
  final bool isPublished;
  final DateTime? publishedAt;

  factory AppReleaseModel.fromMap(Map<String, dynamic> map) {
    final rawChanges = map['changes'];
    return AppReleaseModel(
      id: map['id'] as String,
      platform: map['platform'] as String,
      versionName: map['version_name'] as String,
      buildNumber: (map['build_number'] as num).toInt(),
      title: map['title'] as String,
      purpose: map['purpose'] as String,
      changes: rawChanges is List
          ? rawChanges.map((item) => item.toString()).toList(growable: false)
          : const [],
      instructions: map['instructions'] as String,
      downloadUrl: map['download_url'] as String,
      isPublished: map['is_published'] as bool,
      publishedAt: DateTime.tryParse(map['published_at']?.toString() ?? ''),
    );
  }
}
