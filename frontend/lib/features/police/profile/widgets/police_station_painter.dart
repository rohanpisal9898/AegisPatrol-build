import 'package:flutter/material.dart';

/// Renders a subtle decorative police station architectural illustration on the right of the hero card
class PoliceStationPainter extends CustomPainter {
  final Color tintColor;

  const PoliceStationPainter({
    this.tintColor = const Color(0xFF93C5FD),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final primaryPaint = Paint()
      ..color = tintColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final lightPaint = Paint()
      ..color = tintColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = tintColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Center the main building at w * 0.58
    final cx = w * 0.58;

    // 1. Rooftop Flagpole & Flag
    final polePaint = Paint()
      ..color = tintColor.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx, h * 0.08), Offset(cx, h * 0.30), polePaint);

    final flagPath = Path()
      ..moveTo(cx, h * 0.08)
      ..lineTo(cx + w * 0.16, h * 0.13)
      ..lineTo(cx, h * 0.18)
      ..close();
    canvas.drawPath(flagPath, primaryPaint);

    // 2. Triangular Pediment / Gable Roof
    final pedimentPath = Path()
      ..moveTo(cx, h * 0.28)
      ..lineTo(cx - w * 0.28, h * 0.40)
      ..lineTo(cx + w * 0.28, h * 0.40)
      ..close();
    canvas.drawPath(pedimentPath, lightPaint);
    canvas.drawPath(pedimentPath, linePaint);

    // Small circular rosette/crest inside pediment
    canvas.drawCircle(Offset(cx, h * 0.35), 4, primaryPaint);

    // 3. Entablature Frieze with "POLICE" sign
    final friezeRect = Rect.fromCenter(
      center: Offset(cx, h * 0.45),
      width: w * 0.52,
      height: h * 0.10,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(friezeRect, const Radius.circular(3)), primaryPaint);

    // "POLICE" Text painted inside the frieze banner
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.0,
    );
    const textSpan = TextSpan(text: 'POLICE', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - (textPainter.width / 2), h * 0.45 - (textPainter.height / 2)),
    );

    // 4. Classical Columns / Pillars
    final columnWidth = w * 0.045;
    final columnHeight = h * 0.38;
    final columnTop = h * 0.50;

    // Outer and Inner Columns
    final colOffsets = [-0.20, -0.09, 0.09, 0.20];
    for (final offsetFactor in colOffsets) {
      final colX = cx + (w * offsetFactor) - (columnWidth / 2);
      final colRect = Rect.fromLTWH(colX, columnTop, columnWidth, columnHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(colRect, const Radius.circular(2)), lightPaint);
      canvas.drawRect(Rect.fromLTWH(colX - 1.5, columnTop - 2, columnWidth + 3, 3), primaryPaint); // capital
      canvas.drawRect(Rect.fromLTWH(colX - 1.5, columnTop + columnHeight - 1, columnWidth + 3, 3), primaryPaint); // base
    }

    // 5. Central Arched Entrance Portal
    final portalWidth = w * 0.18;
    final portalTop = h * 0.58;
    final portalLeft = cx - (portalWidth / 2);

    final archPath = Path()
      ..moveTo(portalLeft, columnTop + columnHeight)
      ..lineTo(portalLeft, portalTop)
      ..arcToPoint(
        Offset(portalLeft + portalWidth, portalTop),
        radius: Radius.circular(portalWidth / 2),
      )
      ..lineTo(portalLeft + portalWidth, columnTop + columnHeight)
      ..close();
    canvas.drawPath(archPath, primaryPaint);

    // Inner door shadow
    final innerDoor = Path()
      ..moveTo(portalLeft + 3, columnTop + columnHeight)
      ..lineTo(portalLeft + 3, portalTop + 4)
      ..arcToPoint(
        Offset(portalLeft + portalWidth - 3, portalTop + 4),
        radius: Radius.circular((portalWidth - 6) / 2),
      )
      ..lineTo(portalLeft + portalWidth - 3, columnTop + columnHeight)
      ..close();
    canvas.drawPath(innerDoor, Paint()..color = tintColor.withValues(alpha: 0.40));

    // 6. Stepped Base at the bottom
    final baseRect1 = Rect.fromCenter(
      center: Offset(cx, h * 0.90),
      width: w * 0.64,
      height: h * 0.04,
    );
    canvas.drawRect(baseRect1, primaryPaint);

    final baseRect2 = Rect.fromCenter(
      center: Offset(cx, h * 0.94),
      width: w * 0.74,
      height: h * 0.04,
    );
    canvas.drawRect(baseRect2, lightPaint);

    // 7. Flanking Wing Walls
    final leftWall = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.76)
      ..lineTo(cx - w * 0.28, h * 0.76)
      ..lineTo(cx - w * 0.28, h)
      ..close();
    canvas.drawPath(leftWall, Paint()..color = tintColor.withValues(alpha: 0.25));

    final rightWall = Path()
      ..moveTo(w, h)
      ..lineTo(w, h * 0.76)
      ..lineTo(cx + w * 0.28, h * 0.76)
      ..lineTo(cx + w * 0.28, h)
      ..close();
    canvas.drawPath(rightWall, Paint()..color = tintColor.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(covariant PoliceStationPainter oldDelegate) =>
      oldDelegate.tintColor != tintColor;
}
