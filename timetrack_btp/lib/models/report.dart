class Report {
  final String id;
  final String userId;
  final String worksiteId;
  final String timesheetId;
  final DateTime date;
  final String description;
  final List<String> photoUrls; // Chemins locaux ou URLs distantes des photos
  final bool isSynced; // Pour le fonctionnement hors-ligne

  Report({
    required this.id,
    required this.userId,
    required this.worksiteId,
    required this.timesheetId,
    required this.date,
    required this.description,
    required this.photoUrls,
    required this.isSynced,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      userId: json['userId'],
      worksiteId: json['worksiteId'],
      timesheetId: json['timesheetId'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      photoUrls: List<String>.from(json['photoUrls']),
      isSynced: json['isSynced'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'worksiteId': worksiteId,
      'timesheetId': timesheetId,
      'date': date.toIso8601String(),
      'description': description,
      'photoUrls': photoUrls,
      'isSynced': isSynced,
    };
  }

  Report copyWith({
    String? id,
    String? userId,
    String? worksiteId,
    String? timesheetId,
    DateTime? date,
    String? description,
    List<String>? photoUrls,
    bool? isSynced,
  }) {
    return Report(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      worksiteId: worksiteId ?? this.worksiteId,
      timesheetId: timesheetId ?? this.timesheetId,
      date: date ?? this.date,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}