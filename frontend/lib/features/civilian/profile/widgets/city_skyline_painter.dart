import 'package:flutter/material.dart';

/// Renders a soft mint decorative city skyline illustration with palms at the base of the hero card
class CitySkylinePainter extends CustomPainter {
  final Color skylineColor;

  const CitySkylinePainter({
    this.skylineColor = const Color(0xFFC7E6D0),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final primaryPaint = Paint()
      ..color = skylineColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final secondaryPaint = Paint()
      ..color = skylineColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // 1. Background layer: soft silhouettes of farther towers & soft trees
    final bgPath = Path()..moveTo(0, h);
    bgPath.lineTo(0, h * 0.55);
    bgPath.lineTo(w * 0.05, h * 0.55);
    bgPath.lineTo(w * 0.05, h * 0.48);
    bgPath.lineTo(w * 0.12, h * 0.48);
    bgPath.lineTo(w * 0.12, h * 0.60);
    bgPath.lineTo(w * 0.18, h * 0.60);
    bgPath.lineTo(w * 0.18, h * 0.42);
    bgPath.lineTo(w * 0.24, h * 0.42);
    bgPath.lineTo(w * 0.24, h * 0.58);
    bgPath.lineTo(w * 0.32, h * 0.58);
    bgPath.lineTo(w * 0.35, h * 0.35); // taller background tower
    bgPath.lineTo(w * 0.40, h * 0.35);
    bgPath.lineTo(w * 0.40, h * 0.52);
    bgPath.lineTo(w * 0.48, h * 0.52);
    bgPath.lineTo(w * 0.48, h * 0.30); // center tall tower
    bgPath.lineTo(w * 0.53, h * 0.30);
    bgPath.lineTo(w * 0.53, h * 0.48);
    bgPath.lineTo(w * 0.60, h * 0.48);
    bgPath.lineTo(w * 0.63, h * 0.22); // background high spire
    bgPath.lineTo(w * 0.66, h * 0.22);
    bgPath.lineTo(w * 0.66, h * 0.50);
    bgPath.lineTo(w * 0.73, h * 0.50);
    bgPath.lineTo(w * 0.75, h * 0.36);
    bgPath.lineTo(w * 0.82, h * 0.36);
    bgPath.lineTo(w * 0.82, h * 0.62);
    bgPath.lineTo(w, h * 0.62);
    bgPath.lineTo(w, h);
    bgPath.close();
    canvas.drawPath(bgPath, secondaryPaint);

    // 2. Foreground layer: detailed buildings, dome, arches
    final fgPath = Path()..moveTo(0, h);

    // Left trees/bushes & small buildings
    fgPath.lineTo(0, h * 0.72);
    fgPath.cubicTo(w * 0.02, h * 0.65, w * 0.06, h * 0.65, w * 0.08, h * 0.72);
    fgPath.lineTo(w * 0.10, h * 0.72);
    fgPath.lineTo(w * 0.10, h * 0.58);
    fgPath.lineTo(w * 0.15, h * 0.58);
    fgPath.lineTo(w * 0.15, h * 0.66);

    // Dome building on left
    fgPath.lineTo(w * 0.17, h * 0.66);
    fgPath.cubicTo(w * 0.17, h * 0.52, w * 0.23, h * 0.52, w * 0.23, h * 0.66);
    fgPath.lineTo(w * 0.25, h * 0.66);
    fgPath.lineTo(w * 0.25, h * 0.56);
    fgPath.lineTo(w * 0.29, h * 0.56);
    fgPath.lineTo(w * 0.29, h * 0.68);

    // Center buildings of diverse heights
    fgPath.lineTo(w * 0.33, h * 0.68);
    fgPath.lineTo(w * 0.33, h * 0.46);
    fgPath.lineTo(w * 0.37, h * 0.46);
    fgPath.lineTo(w * 0.37, h * 0.62);
    fgPath.lineTo(w * 0.41, h * 0.62);
    fgPath.lineTo(w * 0.41, h * 0.40);
    // Spire atop building
    fgPath.lineTo(w * 0.425, h * 0.40);
    fgPath.lineTo(w * 0.425, h * 0.32);
    fgPath.lineTo(w * 0.435, h * 0.32);
    fgPath.lineTo(w * 0.435, h * 0.40);
    fgPath.lineTo(w * 0.45, h * 0.40);
    fgPath.lineTo(w * 0.45, h * 0.60);

    // High-rise towers on the right
    fgPath.lineTo(w * 0.50, h * 0.60);
    fgPath.lineTo(w * 0.50, h * 0.38);
    fgPath.lineTo(w * 0.55, h * 0.38);
    fgPath.lineTo(w * 0.55, h * 0.52);
    fgPath.lineTo(w * 0.59, h * 0.52);
    fgPath.lineTo(w * 0.59, h * 0.28); // tall tower
    fgPath.lineTo(w * 0.64, h * 0.28);
    fgPath.lineTo(w * 0.64, h * 0.48);
    fgPath.lineTo(w * 0.68, h * 0.48);
    fgPath.lineTo(w * 0.68, h * 0.35);
    fgPath.lineTo(w * 0.72, h * 0.35);
    fgPath.lineTo(w * 0.72, h * 0.58);
    fgPath.lineTo(w * 0.77, h * 0.58);
    fgPath.lineTo(w * 0.77, h * 0.45);
    fgPath.lineTo(w * 0.81, h * 0.45);
    fgPath.lineTo(w * 0.81, h * 0.75);

    // Right ground line
    fgPath.lineTo(w, h * 0.75);
    fgPath.lineTo(w, h);
    fgPath.close();
    canvas.drawPath(fgPath, primaryPaint);

    // 3. Right Palm Trees (2 distinctive palm trees matching the reference)
    _drawPalmTree(canvas, Offset(w * 0.84, h * 0.78), h * 0.44, primaryPaint);
    _drawPalmTree(canvas, Offset(w * 0.92, h * 0.80), h * 0.38, primaryPaint);
  }

  void _drawPalmTree(Canvas canvas, Offset base, double height, Paint paint) {
    // Curved trunk
    final trunkPath = Path()
      ..moveTo(base.dx - 2.5, base.dy)
      ..cubicTo(base.dx - 1.5, base.dy - height * 0.5, base.dx + 4, base.dy - height * 0.8, base.dx + 6, base.dy - height)
      ..lineTo(base.dx + 8, base.dy - height)
      ..cubicTo(base.dx + 6, base.dy - height * 0.8, base.dx + 1.5, base.dy - height * 0.5, base.dx + 2.5, base.dy)
      ..close();
    canvas.drawPath(trunkPath, paint);

    // Fronds radiating from top
    final top = Offset(base.dx + 7, base.dy - height);
    final frondRadius = height * 0.42;

    // Angles for palm fronds (drooping arcs)
    final angles = [-160.0, -125.0, -90.0, -55.0, -20.0, 15.0];
    for (final angle in angles) {
      final rad = angle * 3.14159 / 180.0;
      final frondTip = Offset(
        top.dx + frondRadius * 1.1 * (angle < -90 ? -1 : 1).abs() * (angle == -90 ? 0.2 : 0.8) * (angle < -90 ? -1 : 1),
        top.dy - frondRadius * 0.5 + (angle.abs() < 90 ? frondRadius * 0.6 : frondRadius * 0.7),
      );

      final frond = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          (top.dx + frondTip.dx) / 2,
          top.dy - frondRadius * 0.35,
          frondTip.dx,
          frondTip.dy,
        )
        ..quadraticBezierTo(
          (top.dx + frondTip.dx) / 2 + 1,
          top.dy - frondRadius * 0.15,
          top.dx,
          top.dy,
        )
        ..close();
      canvas.drawPath(frond, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CitySkylinePainter oldDelegate) =>
      oldDelegate.skylineColor != skylineColor;
}
