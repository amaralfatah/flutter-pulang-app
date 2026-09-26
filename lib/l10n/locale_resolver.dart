import 'dart:ui';

/// Bahasa yang didukung app. Urutan pertama = fallback.
const supportedLanguageCodes = ['id', 'en'];

/// Ubah setting bahasa (`system` / `id` / `en`) menjadi kode bahasa final.
/// `system` memakai [deviceLocale]; bahasa perangkat yang tidak didukung
/// jatuh ke Indonesia. Dipakai oleh MaterialApp dan NotificationService
/// (yang juga berjalan di isolate background tanpa BuildContext).
String resolveLanguageCode(String setting, Locale deviceLocale) {
  if (supportedLanguageCodes.contains(setting)) return setting;
  final device = deviceLocale.languageCode;
  return supportedLanguageCodes.contains(device)
      ? device
      : supportedLanguageCodes.first;
}
