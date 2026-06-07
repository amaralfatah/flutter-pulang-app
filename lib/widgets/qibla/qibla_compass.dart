import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';

import '../../utils/qibla_utils.dart';

/// Visual compass: a dial that rotates with the device heading and a needle
/// that points to the Qibla.
class QiblaCompass extends StatelessWidget {
  const QiblaCompass({super.key, required this.direction});

  final QiblahDirection direction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final aligned = QiblaUtils.isFacingQibla(direction.qiblah);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          aligned ? 'Anda menghadap kiblat' : 'Putar perangkat ke arah panah',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: aligned ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -direction.direction * (math.pi / 180),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: const _DialLabels(),
                ),
              ),
              Transform.rotate(
                angle: direction.qiblah * (math.pi / 180),
                child: Icon(
                  Icons.navigation,
                  size: 120,
                  color: aligned ? colorScheme.primary : colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${QiblaUtils.formatDegrees(direction.direction)} '
          '${QiblaUtils.cardinalDirection(direction.direction)}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class _DialLabels extends StatelessWidget {
  const _DialLabels();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Text('U', style: style?.copyWith(color: Colors.red)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text('S', style: style),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('B', style: style),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('T', style: style),
          ),
        ],
      ),
    );
  }
}
