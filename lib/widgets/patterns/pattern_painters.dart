import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Islamic geometric pattern painter untuk background card
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  IslamicPatternPainter({required this.color, this.opacity = 0.08});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 40.0;
    final int cols = (size.width / spacing).ceil() + 1;
    final int rows = (size.height / spacing).ceil() + 1;

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final double x = i * spacing;
        final double y = j * spacing;

        // Draw 8-pointed star pattern (common in Islamic art)
        _drawEightPointedStar(canvas, Offset(x, y), spacing * 0.35, paint);
      }
    }
  }

  void _drawEightPointedStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path();

    // Create 8-pointed star using two overlapping squares rotated 45 degrees
    for (int i = 0; i < 8; i++) {
      final double angle = (i * math.pi / 4) - math.pi / 8;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // Inner circle for detail
    canvas.drawCircle(center, radius * 0.3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kawung-inspired batik pattern (simplified)
class KawungPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  KawungPatternPainter({required this.color, this.opacity = 0.1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const double spacing = 50.0;
    final int cols = (size.width / spacing).ceil() + 1;
    final int rows = (size.height / spacing).ceil() + 1;

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        // Offset every other row for kawung effect
        final double offsetX = (j % 2 == 0) ? 0 : spacing / 2;
        final double x = i * spacing + offsetX;
        final double y = j * spacing * 0.8;

        _drawKawungMotif(canvas, Offset(x, y), spacing * 0.35, paint);
      }
    }
  }

  void _drawKawungMotif(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    // Draw 4 overlapping ovals (kawung pattern)
    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2;
      final double offsetX = math.cos(angle) * radius * 0.4;
      final double offsetY = math.sin(angle) * radius * 0.4;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + offsetX, center.dy + offsetY),
          width: radius * 0.6,
          height: radius * 0.9,
        ),
        paint,
      );
    }

    // Center dot
    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.12, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simple arabesque/floral pattern
class ArabesquePatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  ArabesquePatternPainter({required this.color, this.opacity = 0.08});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 60.0;
    final int cols = (size.width / spacing).ceil() + 1;
    final int rows = (size.height / spacing).ceil() + 1;

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final double x = i * spacing;
        final double y = j * spacing;

        _drawArabesqueMotif(canvas, Offset(x, y), spacing * 0.4, paint);
      }
    }
  }

  void _drawArabesqueMotif(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    // Draw curved diamond shape
    final path = Path();

    // Top curve
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(
      center.dx + radius * 0.5,
      center.dy - radius * 0.5,
      center.dx + radius,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx + radius * 0.5,
      center.dy + radius * 0.5,
      center.dx,
      center.dy + radius,
    );
    path.quadraticBezierTo(
      center.dx - radius * 0.5,
      center.dy + radius * 0.5,
      center.dx - radius,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx - radius * 0.5,
      center.dy - radius * 0.5,
      center.dx,
      center.dy - radius,
    );

    canvas.drawPath(path, paint);

    // Inner detail
    canvas.drawCircle(center, radius * 0.2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
