import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';

import '../../app/extensions/context_extensions.dart';
import '../../utils/qibla_utils.dart';

/// Visual compass: a rose that rotates with the device heading, a needle that
/// points to the Qibla and a fixed marker for the direction the user faces.
class QiblaCompass extends StatefulWidget {
  const QiblaCompass({super.key, required this.direction});

  final QiblahDirection direction;

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass> {
  bool _wasAligned = false;

  @override
  void initState() {
    super.initState();
    _wasAligned = QiblaUtils.isFacingQibla(widget.direction.qiblah);
  }

  @override
  void didUpdateWidget(QiblaCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    final aligned = QiblaUtils.isFacingQibla(widget.direction.qiblah);
    // Confirm with a single haptic pulse the moment the user lines up.
    if (aligned && !_wasAligned) {
      HapticFeedback.mediumImpact();
    }
    _wasAligned = aligned;
  }

  @override
  Widget build(BuildContext context) {
    final direction = widget.direction;
    final aligned = QiblaUtils.isFacingQibla(direction.qiblah);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep the dial comfortable on small phones and in landscape.
        final maxDiameter = math.min(
          constraints.maxWidth - 48,
          constraints.maxHeight - 220,
        );
        final diameter = maxDiameter.clamp(220.0, 320.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusPill(aligned: aligned),
            const SizedBox(height: 32),
            _CompassDial(
              diameter: diameter,
              direction: direction,
              aligned: aligned,
            ),
            const SizedBox(height: 32),
            _QiblaInfoCard(direction: direction),
          ],
        );
      },
    );
  }
}

/// Animated chip that confirms whether the device is facing the Qibla.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.aligned});

  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final background = aligned
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foreground = aligned
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            aligned
                ? Icons.check_circle_rounded
                : Icons.screen_rotation_alt_rounded,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Text(
            aligned ? 'Anda menghadap kiblat' : 'Putar perangkat ke arah panah',
            style: context.textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The circular dial: glow, surface, rotating rose, Qibla needle, hub and the
/// fixed pointer marking the direction the user is physically facing.
class _CompassDial extends StatelessWidget {
  const _CompassDial({
    required this.diameter,
    required this.direction,
    required this.aligned,
  });

  final double diameter;
  final QiblahDirection direction;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final needleColor = aligned ? colorScheme.primary : colorScheme.tertiary;

    return Semantics(
      label: 'Kompas kiblat',
      value:
          'Arah kiblat ${QiblaUtils.formatDegrees(direction.offset)}, '
          '${aligned ? 'Anda menghadap kiblat' : 'belum sejajar, putar perangkat ke arah panah'}',
      liveRegion: true,
      child: SizedBox(
        width: diameter,
        // Extra room above the dial for the fixed facing pointer.
        height: diameter + 20,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Soft halo that lights up once aligned.
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: aligned
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.45),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ]
                    : const [],
              ),
            ),

            // Dial face.
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHigh,
                border: Border.all(
                  color: aligned
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: aligned ? 2 : 1,
                ),
              ),
            ),

            // Rotating rose: ticks + cardinal labels track real-world directions.
            Transform.rotate(
              angle: -direction.direction * (math.pi / 180),
              child: CustomPaint(
                size: Size.square(diameter),
                painter: _CompassRosePainter(
                  minorTick: colorScheme.outlineVariant,
                  majorTick: colorScheme.outline,
                  cardinalColor: colorScheme.onSurfaceVariant,
                  northColor: colorScheme.error,
                  textStyle: context.textTheme.labelMedium,
                  northTextStyle: context.textTheme.titleMedium,
                ),
              ),
            ),

            // Needle pointing to the Qibla.
            Transform.rotate(
              angle: -direction.qiblah * (math.pi / 180),
              child: CustomPaint(
                size: Size.square(diameter),
                painter: _NeedlePainter(
                  color: needleColor,
                  tailColor: colorScheme.outlineVariant,
                  shadowColor: colorScheme.shadow,
                ),
              ),
            ),

            // Center hub representing the Kaaba (destination).
            Container(
              width: diameter * 0.2,
              height: diameter * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                border: Border.all(color: needleColor, width: 2),
              ),
              child: Icon(
                Icons.mosque_rounded,
                size: diameter * 0.1,
                color: needleColor,
              ),
            ),

            // Fixed pointer above the dial = the direction you currently face.
            Positioned(
              top: -2,
              child: Icon(
                Icons.arrow_drop_down_rounded,
                size: 40,
                color: needleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom card with the Qibla bearing for the user's location.
class _QiblaInfoCard extends StatelessWidget {
  const _QiblaInfoCard({required this.direction});

  final QiblahDirection direction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardinal = QiblaUtils.cardinalDirection(direction.offset);

    return Card.filled(
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_rounded, color: colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Arah kiblat',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${QiblaUtils.formatDegrees(direction.offset)} '
                  '${QiblaUtils.cardinalName(cardinal)}',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the dial ticks and cardinal letters around the rim.
class _CompassRosePainter extends CustomPainter {
  _CompassRosePainter({
    required this.minorTick,
    required this.majorTick,
    required this.cardinalColor,
    required this.northColor,
    required this.textStyle,
    required this.northTextStyle,
  });

  final Color minorTick;
  final Color majorTick;
  final Color cardinalColor;
  final Color northColor;
  final TextStyle? textStyle;
  final TextStyle? northTextStyle;

  static const _cardinals = {
    0: 'U',
    45: 'TL',
    90: 'T',
    135: 'TG',
    180: 'S',
    225: 'BD',
    270: 'B',
    315: 'BL',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    for (var deg = 0; deg < 360; deg += 5) {
      final isMajor = deg % 45 == 0;
      final isMedium = deg % 15 == 0;
      final tickLength = isMajor
          ? 14.0
          : isMedium
          ? 9.0
          : 5.0;
      final paint = Paint()
        ..color = isMajor ? majorTick : minorTick
        ..strokeWidth = isMajor ? 2.5 : 1.0
        ..strokeCap = StrokeCap.round;

      final angle = deg * (math.pi / 180) - math.pi / 2;
      final unit = Offset(math.cos(angle), math.sin(angle));
      final outer = center + unit * (radius - 8);
      final inner = center + unit * (radius - 8 - tickLength);
      canvas.drawLine(inner, outer, paint);
    }

    _cardinals.forEach((deg, label) {
      final isPrimary = deg % 90 == 0;
      final style = (isPrimary ? northTextStyle : textStyle)?.copyWith(
        color: deg == 0 ? northColor : cardinalColor,
        fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
      );
      _drawLabel(canvas, center, radius, deg.toDouble(), label, style);
    });
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double deg,
    String text,
    TextStyle? style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final angle = deg * (math.pi / 180) - math.pi / 2;
    final unit = Offset(math.cos(angle), math.sin(angle));
    final position =
        center +
        unit * (radius - 34) -
        Offset(painter.width / 2, painter.height / 2);
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(_CompassRosePainter oldDelegate) =>
      oldDelegate.minorTick != minorTick ||
      oldDelegate.majorTick != majorTick ||
      oldDelegate.cardinalColor != cardinalColor ||
      oldDelegate.northColor != northColor;
}

/// Draws a slim arrow pointing up from the centre, with a short muted tail
/// for the opposite end. The box centre is the pivot.
class _NeedlePainter extends CustomPainter {
  _NeedlePainter({
    required this.color,
    required this.tailColor,
    required this.shadowColor,
  });

  final Color color;
  final Color tailColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final tipY = cy - (size.height / 2 - 40);

    const headHalfWidth = 13.0;
    const shaftHalfWidth = 3.5;
    final headLength = tipY + 36;

    final arrow = Path()
      ..moveTo(cx, tipY) // tip
      ..lineTo(cx - headHalfWidth, headLength)
      ..lineTo(cx - shaftHalfWidth, headLength)
      ..lineTo(cx - shaftHalfWidth, cy)
      ..lineTo(cx + shaftHalfWidth, cy)
      ..lineTo(cx + shaftHalfWidth, headLength)
      ..lineTo(cx + headHalfWidth, headLength)
      ..close();

    // Subtle depth under the needle, using the theme's shadow token so it
    // adapts to light/dark instead of a hardcoded black.
    canvas.drawShadow(arrow, shadowColor, 4, false);
    canvas.drawPath(arrow, Paint()..color = color);

    // Short muted tail towards the opposite direction.
    final tailEnd = cy + (size.height / 2 - 40) * 0.45;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, tailEnd),
      Paint()
        ..color = tailColor
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_NeedlePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.tailColor != tailColor ||
      oldDelegate.shadowColor != shadowColor;
}
