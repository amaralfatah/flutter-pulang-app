import 'dart:async';

/// Memantau pergantian hari supaya layar yang menampilkan "hari ini" ikut
/// menyegarkan diri saat lewat tengah malam.
///
/// Dulu service ini juga menandai solat kemarin sebagai terlewat. Itu sudah
/// dilepas: slot yang tidak tercatat kini dibiarkan kosong dan dihitung sebagai
/// "belum tercatat", karena aplikasi tidak bisa membedakan solat yang memang
/// ditinggalkan dari solat yang lupa dicatat.
class DateChangeService {
  Timer? _timer;
  String _lastCheckedDate = '';

  /// Dipanggil sekali setiap kali tanggal berganti.
  final void Function()? onDateChanged;

  DateChangeService({this.onDateChanged});

  /// Start monitoring for date changes
  void startMonitoring() {
    _lastCheckedDate = _getCurrentDate();

    // Check every minute if date has changed
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final currentDate = _getCurrentDate();

      if (currentDate != _lastCheckedDate) {
        _lastCheckedDate = currentDate;
        onDateChanged?.call();
      }
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  /// Get current date as string (YYYY-MM-DD)
  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
