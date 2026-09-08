import 'package:flutter/material.dart';

/// Reusable vector-rendered female avatar matching the reference illustration
class FemaleAvatar extends StatelessWidget {
  final double size;

  const FemaleAvatar({
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
        color: const Color(0xFFEAF5EE),
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
          painter: _FemaleAvatarPainter(),
        ),
      ),
    );
  }
}

class _FemaleAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background circle fill
    final bgPaint = Paint()..color = const Color(0xFFE8F5EE);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final skinPaint = Paint()..color = const Color(0xFFFBD7BE);
    final skinShadowPaint = Paint()..color = const Color(0xFFF2C3A7);
    final hairPaint = Paint()..color = const Color(0xFF1E293B);
    final clothesPaint = Paint()..color = const Color(0xFF0D7A48);
    final collarPaint = Paint()..color = const Color(0xFF0A633A);

    // 1. Back Hair (silhouette behind shoulders and head)
    final backHairPath = Path()
      ..moveTo(w * 0.22, h * 0.40)
      ..cubicTo(w * 0.14, h * 0.50, w * 0.16, h * 0.72, w * 0.22, h * 0.82)
      ..lineTo(w * 0.78, h * 0.82)
      ..cubicTo(w * 0.84, h * 0.72, w * 0.86, h * 0.50, w * 0.78, h * 0.40)
      ..close();
    canvas.drawPath(backHairPath, hairPaint);

    // 2. Neck
    final neckPath = Path()
      ..moveTo(w * 0.43, h * 0.52)
      ..lineTo(w * 0.43, h * 0.70)
      ..cubicTo(w * 0.43, h * 0.74, w * 0.57, h * 0.74, w * 0.57, h * 0.70)
      ..lineTo(w * 0.57, h * 0.52)
      ..close();
    canvas.drawPath(neckPath, skinShadowPaint);

    // 3. Green Clothing / Shoulders
    final clothesPath = Path()
      ..moveTo(w * 0.10, h * 1.0)
      ..cubicTo(w * 0.12, h * 0.78, w * 0.32, h * 0.72, w * 0.40, h * 0.73)
      ..cubicTo(w * 0.45, h * 0.80, w * 0.55, h * 0.80, w * 0.60, h * 0.73)
      ..cubicTo(w * 0.68, h * 0.72, w * 0.88, h * 0.78, w * 0.90, h * 1.0)
      ..close();
    canvas.drawPath(clothesPath, clothesPaint);

    // Collar detail
    final collarPath = Path()
      ..moveTo(w * 0.40, h * 0.73)
      ..cubicTo(w * 0.46, h * 0.80, w * 0.54, h * 0.80, w * 0.60, h * 0.73)
      ..cubicTo(w * 0.56, h * 0.83, w * 0.44, h * 0.83, w * 0.40, h * 0.73)
      ..close();
    canvas.drawPath(collarPath, collarPaint);

    // 4. Face (oval head)
    final facePath = Path()
      ..moveTo(w * 0.33, h * 0.38)
      ..cubicTo(w * 0.33, h * 0.22, w * 0.67, h * 0.22, w * 0.67, h * 0.38)
      ..cubicTo(w * 0.67, h * 0.54, w * 0.58, h * 0.62, w * 0.50, h * 0.63)
      ..cubicTo(w * 0.42, h * 0.62, w * 0.33, h * 0.54, w * 0.33, h * 0.38)
      ..close();
    canvas.drawPath(facePath, skinPaint);

    // Subtle face shadow under chin
    final chinShadow = Path()
      ..moveTo(w * 0.45, h * 0.62)
      ..cubicTo(w * 0.48, h * 0.635, w * 0.52, h * 0.635, w * 0.55, h * 0.62)
      ..cubicTo(w * 0.52, h * 0.645, w * 0.48, h * 0.645, w * 0.45, h * 0.62)
      ..close();
    canvas.drawPath(chinShadow, skinShadowPaint);

    // 5. Front Hair (Center parted, styled with volume and wavy framing)
    final frontHairPath = Path()
      // Center part at top
      ..moveTo(w * 0.50, h * 0.22)
      // Left forehead wave
      ..cubicTo(w * 0.44, h * 0.22, w * 0.38, h * 0.27, w * 0.35, h * 0.36)
      ..cubicTo(w * 0.31, h * 0.46, w * 0.29, h * 0.58, w * 0.26, h * 0.72)
      ..cubicTo(w * 0.24, h * 0.80, w * 0.30, h * 0.82, w * 0.33, h * 0.74)
      ..cubicTo(w * 0.35, h * 0.64, w * 0.36, h * 0.52, w * 0.40, h * 0.42)
      ..cubicTo(w * 0.44, h * 0.32, w * 0.48, h * 0.27, w * 0.50, h * 0.26)
      // Right forehead wave
      ..cubicTo(w * 0.52, h * 0.27, w * 0.56, h * 0.32, w * 0.60, h * 0.42)
      ..cubicTo(w * 0.64, h * 0.52, w * 0.65, h * 0.64, w * 0.67, h * 0.74)
      ..cubicTo(w * 0.70, h * 0.82, w * 0.76, h * 0.80, w * 0.74, h * 0.72)
      ..cubicTo(w * 0.71, h * 0.58, w * 0.69, h * 0.46, w * 0.65, h * 0.36)
      ..cubicTo(w * 0.62, h * 0.27, w * 0.56, h * 0.22, w * 0.50, h * 0.22)
      ..close();
    canvas.drawPath(frontHairPath, hairPaint);

    // Top hair volume
    final topHairPath = Path()
      ..moveTo(w * 0.28, h * 0.32)
      ..cubicTo(w * 0.28, h * 0.16, w * 0.72, h * 0.16, w * 0.72, h * 0.32)
      ..cubicTo(w * 0.65, h * 0.22, w * 0.35, h * 0.22, w * 0.28, h * 0.32)
      ..close();
    canvas.drawPath(topHairPath, hairPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
