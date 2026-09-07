class AlertModel {
  final String id;
  final String userId;
  final String? journeyId;
  final String alertType;
  final String status;
  final double lat;
  final double lon;
  final String? h3Cell;
  final double? riskScore;
  final String? message;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    required this.userId,
    this.journeyId,
    required this.alertType,
    required this.status,
    required this.lat,
    required this.lon,
    this.h3Cell,
    this.riskScore,
    this.message,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      journeyId: json['journey_id'],
      alertType: json['alert_type'] ?? 'safety_alert',
      status: json['status'] ?? 'active',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      h3Cell: json['h3_cell'],
      riskScore: (json['risk_score'] as num?)?.toDouble(),
      message: json['message'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
