/// Pure helpers for the Qibla compass UI.
///
/// These have no Flutter or sensor dependencies so they can be unit-tested in
/// isolation.
class QiblaUtils {
  QiblaUtils._();

  /// Normalise any angle into the [0, 360) range.
  static double normalizeDegrees(double degrees) {
    final mod = degrees % 360;
    return mod < 0 ? mod + 360 : mod;
  }

  /// 8-point Indonesian cardinal abbreviation for a heading in degrees.
  ///
  /// Input is normalised first. `0` means north, increasing clockwise.
  static String cardinalDirection(double degrees) {
    final normalized = normalizeDegrees(degrees);
    const labels = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL'];
    final index = ((normalized + 22.5) ~/ 45) % 8;
    return labels[index];
  }

  /// Whether the device points at the Qibla within [tolerance] degrees.
  ///
  /// [qiblah] is the `QiblahDirection.qiblah` value where `0` is aligned.
  static bool isFacingQibla(double qiblah, {double tolerance = 5}) {
    final normalized = normalizeDegrees(qiblah);
    return normalized <= tolerance || normalized >= 360 - tolerance;
  }

  /// Format a heading for display, e.g. `123.4` -> `123°`.
  static String formatDegrees(double degrees) {
    return '${normalizeDegrees(degrees).round()}\u00B0';
  }
}
