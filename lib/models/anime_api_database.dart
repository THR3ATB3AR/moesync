class AnimeApiDatabaseMetadata {
  const AnimeApiDatabaseMetadata({
    required this.recordCount,
    required this.downloadedAt,
    this.sourceUpdatedAt,
  });

  final int recordCount;
  final DateTime downloadedAt;
  final DateTime? sourceUpdatedAt;

  Map<String, dynamic> toJson() => {
    'recordCount': recordCount,
    'downloadedAt': downloadedAt.toIso8601String(),
    'sourceUpdatedAt': sourceUpdatedAt?.toIso8601String(),
  };

  factory AnimeApiDatabaseMetadata.fromJson(Map<String, dynamic> json) {
    final recordCount = json['recordCount'];
    final downloadedAt = json['downloadedAt'];
    if (recordCount is! int || downloadedAt is! String) {
      throw const FormatException('Invalid AnimeApi database metadata.');
    }
    final parsedDownloadedAt = DateTime.tryParse(downloadedAt);
    if (parsedDownloadedAt == null) {
      throw const FormatException('Invalid AnimeApi database download date.');
    }
    final sourceUpdatedAt = json['sourceUpdatedAt'];
    return AnimeApiDatabaseMetadata(
      recordCount: recordCount,
      downloadedAt: parsedDownloadedAt,
      sourceUpdatedAt: sourceUpdatedAt is String
          ? DateTime.tryParse(sourceUpdatedAt)
          : null,
    );
  }
}

class AnimeApiRecord {
  const AnimeApiRecord({required this.title, required this.ids});

  final String title;
  final Map<String, String> ids;
}
