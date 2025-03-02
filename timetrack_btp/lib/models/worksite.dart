class Worksite {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radius; // Rayon en mètres pour la géolocalisation
  final String? description;
  final String? clientName;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> assignedEmployees; // Liste des IDs des employés assignés à ce chantier

  Worksite({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.startDate,
    this.description,
    this.clientName,
    this.endDate,
    this.assignedEmployees = const [],
  });

  factory Worksite.fromJson(Map<String, dynamic> json) {
    return Worksite(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'],
      description: json['description'],
      clientName: json['clientName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      assignedEmployees: json['assignedEmployees'] != null 
          ? List<String>.from(json['assignedEmployees'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'description': description,
      'clientName': clientName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'assignedEmployees': assignedEmployees,
    };
  }
}