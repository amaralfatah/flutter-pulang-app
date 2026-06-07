import 'package:flutter_test/flutter_test.dart';
import 'package:pulang/utils/qibla_utils.dart';

void main() {
  group('normalizeDegrees', () {
    test('keeps values already in range', () {
      expect(QiblaUtils.normalizeDegrees(123), 123);
    });

    test('wraps values >= 360', () {
      expect(QiblaUtils.normalizeDegrees(370), 10);
    });

    test('wraps negative values', () {
      expect(QiblaUtils.normalizeDegrees(-45), 315);
    });
  });

  group('cardinalDirection', () {
    test('maps the four main points', () {
      expect(QiblaUtils.cardinalDirection(0), 'U');
      expect(QiblaUtils.cardinalDirection(90), 'T');
      expect(QiblaUtils.cardinalDirection(180), 'S');
      expect(QiblaUtils.cardinalDirection(270), 'B');
    });

    test('wraps 360 back to north', () {
      expect(QiblaUtils.cardinalDirection(360), 'U');
    });

    test('maps an intercardinal point', () {
      expect(QiblaUtils.cardinalDirection(45), 'TL');
    });

    test('normalises negative input', () {
      expect(QiblaUtils.cardinalDirection(-10), 'U');
    });
  });

  group('isFacingQibla', () {
    test('true when within tolerance of 0', () {
      expect(QiblaUtils.isFacingQibla(3), isTrue);
    });

    test('true when just below 360', () {
      expect(QiblaUtils.isFacingQibla(358), isTrue);
    });

    test('false when clearly off', () {
      expect(QiblaUtils.isFacingQibla(45), isFalse);
    });
  });

  group('formatDegrees', () {
    test('rounds and appends the degree sign', () {
      expect(QiblaUtils.formatDegrees(123.4), '123\u00B0');
    });
  });

  group('cardinalName', () {
    test('expands known abbreviations', () {
      expect(QiblaUtils.cardinalName('U'), 'Utara');
      expect(QiblaUtils.cardinalName('BL'), 'Barat Laut');
    });

    test('returns unknown abbreviations unchanged', () {
      expect(QiblaUtils.cardinalName('X'), 'X');
    });
  });
}
