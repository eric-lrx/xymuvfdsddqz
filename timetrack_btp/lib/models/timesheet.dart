class Timesheet {
  final String id;
  final String userId;
  final String worksiteId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double checkInLatitude;
  final double checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final bool isValid; // Pour indiquer si le pointage est sur le bon chantier
  final bool isSynced; // Pour le fonctionnement hors-ligne

  Timesheet({
    required this.id,
    required this.userId,
    required this.worksiteId,
    required this.checkInTime,
    required this.checkInLatitude,
    required this.checkInLongitude,
    this.checkOutTime,
    this.checkOutLatitude,
    this.checkOutLongitude,
    required this.isValid,
    required this.isSynced,
  });

  factory Timesheet.fromJson(Map<String, dynamic> json) {
    return Timesheet(
      id: json['id'],
      userId: json['userId'],
      worksiteId: json['worksiteId'],
      checkInTime: DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      checkInLatitude: json['checkInLatitude'],
      checkInLongitude: json['checkInLongitude'],
      checkOutLatitude: json['checkOutLatitude'],
      checkOutLongitude: json['checkOutLongitude'],
      isValid: json['isValid'],
      isSynced: json['isSynced'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'worksiteId': worksiteId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'isValid': isValid,
      'isSynced': isSynced,
    };
  }

  Timesheet copyWith({
    String? id,
    String? userId,
    String? worksiteId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    bool? isValid,
    bool? isSynced,
  }) {
    return Timesheet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      worksiteId: worksiteId ?? this.worksiteId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      isValid: isValid ?? this.isValid,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}