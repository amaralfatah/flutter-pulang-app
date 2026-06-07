import 'package:flutter/material.dart';

/// M3-compliant SnackBars with guaranteed on-color pairing.
///
/// Each builder returns a [SnackBar] whose foreground (text + icon) is the
/// matching `on` token for the background, so contrast always holds. A leading
/// icon is included so meaning is never conveyed by colour alone (WCAG / M3
/// `color-not-only`). Callers pass the resolved [ColorScheme] which keeps the
/// helper usable after async gaps where the original `BuildContext` may be gone:
///
/// ```dart
/// messenger.showSnackBar(AppSnackBar.success(colorScheme, 'Backup berhasil!'));
/// ```
class AppSnackBar {
  AppSnackBar._();

  /// Positive confirmation. Uses `primary` (the app has no dedicated success
  /// token) paired with `onPrimary`.
  static SnackBar success(ColorScheme colorScheme, String message) => _build(
    background: colorScheme.primary,
    foreground: colorScheme.onPrimary,
    icon: Icons.check_circle_rounded,
    message: message,
  );

  /// Failure / blocking error. Uses the semantic `error` role.
  static SnackBar error(ColorScheme colorScheme, String message) => _build(
    background: colorScheme.error,
    foreground: colorScheme.onError,
    icon: Icons.error_rounded,
    message: message,
  );

  /// Neutral / in-progress information. Uses the M3 default SnackBar tones
  /// (`inverseSurface`/`onInverseSurface`) rather than a brand colour.
  static SnackBar info(ColorScheme colorScheme, String message) => _build(
    background: colorScheme.inverseSurface,
    foreground: colorScheme.onInverseSurface,
    icon: Icons.info_rounded,
    message: message,
  );

  static SnackBar _build({
    required Color background,
    required Color foreground,
    required IconData icon,
    required String message,
  }) {
    return SnackBar(
      backgroundColor: background,
      content: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}
