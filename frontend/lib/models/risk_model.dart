import 'journey_model.dart';

class RiskEvaluationResult {
  final String journeyId;
  final String? h3Cell;
  final double riskScore;
  final RiskLevel riskLevel;
  final JourneyStatus status;
  final String message;

  const RiskEvaluationResult({
    required this.journeyId,
    this.h3Cell,
    required this.riskScore,
    required this.riskLevel,
    required this.status,
    required this.message,
  });

  factory RiskEvaluationResult.fromJson(Map<String, dynamic> json) {
    return RiskEvaluationResult(
      journeyId: json['journey_id'] ?? '',
      h3Cell: json['h3_cell'],
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      riskLevel: RiskLevel.fromString(json['risk_level']),
      status: JourneyStatus.fromString(json['status']),
      message: json['message'] ?? '',
    );
  }
}
