import 'package:flutter/material.dart';

/// Reusable vector-rendered police officer avatar matching the reference illustration
class PoliceOfficerAvatar extends StatelessWidget {
  final double size;

  const PoliceOfficerAvatar({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE0EDFB), // Soft light-blue background
        border: Border.all(color: Colors.white, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _PoliceOfficerAvatarPainter(),
        ),
      ),
    );
  }
}

class _PoliceOfficerAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background circle fill
    final bgPaint = Paint()..color = const Color(0xFFE0EDFB);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final skinPaint = Paint()..color = const Color(0xFFFBD7BE);
    final skinShadowPaint = Paint()..color = const Color(0xFFF2C3A7);
    final hairPaint = Paint()..color = const Color(0xFF1E293B);
    final capCrownPaint = Paint()..color = const Color(0xFF263238); // Dark charcoal cap
    final capVisorPaint = Paint()..color = const Color(0xFF0F172A); // Black visor
    final badgePaint = Paint()..color = const Color(0xFFF59E0B); // Amber gold badge
    final khakiPaint = Paint()..color = const Color(0xFFD7BF9F); // Khaki police uniform
    final khakiDarkPaint = Paint()..color = const Color(0xFFC8AE8C); // Collar shadow
    final epauletPaint = Paint()..color = const Color(0xFF1E293B); // Dark shoulder epaulets

    // 1. Khaki Uniform Shoulders & Chest
    final shirtPath = Path()
      ..moveTo(w * 0.08, h * 1.0)
      ..cubicTo(w * 0.10, h * 0.76, w * 0.30, h * 0.70, w * 0.40, h * 0.72)
      ..cubicTo(w * 0.45, h * 0.82, w * 0.55, h * 0.82, w * 0.60, h * 0.72)
      ..cubicTo(w * 0.70, h * 0.70, w * 0.90, h * 0.76, w * 0.92, h * 1.0)
      ..close();
    canvas.drawPath(shirtPath, khakiPaint);

    // Left & Right Epaulets (dark shoulder straps with gold button)
    final leftEpaulet = Path()
      ..moveTo(w * 0.12, h * 0.85)
      ..lineTo(w * 0.28, h * 0.76)
      ..lineTo(w * 0.26, h * 0.72)
      ..lineTo(w * 0.10, h * 0.80)
      ..close();
    canvas.drawPath(leftEpaulet, epauletPaint);

    final rightEpaulet = Path()
      ..moveTo(w * 0.88, h * 0.85)
      ..lineTo(w * 0.72, h * 0.76)
      ..lineTo(w * 0.74, h * 0.72)
      ..lineTo(w * 0.90, h * 0.80)
      ..close();
    canvas.drawPath(rightEpaulet, epauletPaint);

    // Gold buttons on epaulets
    canvas.drawCircle(Offset(w * 0.25, h * 0.75), 1.8, badgePaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.75), 1.8, badgePaint);

    // 2. Neck
    final neckPath = Path()
      ..moveTo(w * 0.42, h * 0.56)
      ..lineTo(w * 0.42, h * 0.73)
      ..cubicTo(w * 0.42, h * 0.77, w * 0.58, h * 0.77, w * 0.58, h * 0.73)
      ..lineTo(w * 0.58, h * 0.56)
      ..close();
    canvas.drawPath(neckPath, skinShadowPaint);

    // Shirt collar flaps
    final leftCollar = Path()
      ..moveTo(w * 0.40, h * 0.72)
      ..lineTo(w * 0.35, h * 0.82)
      ..lineTo(w * 0.46, h * 0.78)
      ..close();
    canvas.drawPath(leftCollar, khakiDarkPaint);

    final rightCollar = Path()
      ..moveTo(w * 0.60, h * 0.72)
      ..lineTo(w * 0.65, h * 0.82)
      ..lineTo(w * 0.54, h * 0.78)
      ..close();
    canvas.drawPath(rightCollar, khakiDarkPaint);

    // 3. Head & Face
    final facePath = Path()
      ..moveTo(w * 0.32, h * 0.42)
      ..cubicTo(w * 0.32, h * 0.28, w * 0.68, h * 0.28, w * 0.68, h * 0.42)
      ..cubicTo(w * 0.68, h * 0.58, w * 0.58, h * 0.66, w * 0.50, h * 0.67)
      ..cubicTo(w * 0.42, h * 0.66, w * 0.32, h * 0.58, w * 0.32, h * 0.42)
      ..close();
    canvas.drawPath(facePath, skinPaint);

    // Ears
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.31, h * 0.46), width: w * 0.07, height: h * 0.12), skinPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.69, h * 0.46), width: w * 0.07, height: h * 0.12), skinPaint);

    // Dark sideburns / hair
    final leftHair = Path()
      ..moveTo(w * 0.32, h * 0.40)
      ..lineTo(w * 0.32, h * 0.48)
      ..lineTo(w * 0.35, h * 0.48)
      ..lineTo(w * 0.35, h * 0.40)
      ..close();
    canvas.drawPath(leftHair, hairPaint);

    final rightHair = Path()
      ..moveTo(w * 0.68, h * 0.40)
      ..lineTo(w * 0.68, h * 0.48)
      ..lineTo(w * 0.65, h * 0.48)
      ..lineTo(w * 0.65, h * 0.40)
      ..close();
    canvas.drawPath(rightHair, hairPaint);

    // 4. Police Peaked Cap
    // Cap Crown (wide flared top)
    final crownPath = Path()
      ..moveTo(w * 0.27, h * 0.32)
      ..cubicTo(w * 0.20, h * 0.22, w * 0.28, h * 0.14, w * 0.50, h * 0.13)
      ..cubicTo(w * 0.72, h * 0.14, w * 0.80, h * 0.22, w * 0.73, h * 0.32)
      ..close();
    canvas.drawPath(crownPath, capCrownPaint);

    // Cap Band (horizontal band above forehead)
    final bandPath = Path()
      ..moveTo(w * 0.27, h * 0.32)
      ..lineTo(w * 0.73, h * 0.32)
      ..cubicTo(w * 0.73, h * 0.36, w * 0.27, h * 0.36, w * 0.27, h * 0.32)
      ..close();
    canvas.drawPath(bandPath, epauletPaint);

    // Gold Police Star/Badge on Cap front
    final badgePath = Path()
      ..moveTo(w * 0.50, h * 0.20)
      ..lineTo(w * 0.54, h * 0.24)
      ..lineTo(w * 0.52, h * 0.29)
      ..lineTo(w * 0.48, h * 0.29)
      ..lineTo(w * 0.46, h * 0.24)
      ..close();
    canvas.drawPath(badgePath, badgePaint);

    // Cap Visor / Brim (curved downwards over forehead)
    final visorPath = Path()
      ..moveTo(w * 0.26, h * 0.34)
      ..cubicTo(w * 0.36, h * 0.41, w * 0.64, h * 0.41, w * 0.74, h * 0.34)
      ..cubicTo(w * 0.62, h * 0.37, w * 0.38, h * 0.37, w * 0.26, h * 0.34)
      ..close();
    canvas.drawPath(visorPath, capVisorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
