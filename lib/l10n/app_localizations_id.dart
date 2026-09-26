// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Pulang - Presensi Solat';

  @override
  String prayerName(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'subuh': 'Subuh',
      'dzuhur': 'Dzuhur',
      'ashar': 'Ashar',
      'maghrib': 'Maghrib',
      'isya': 'Isya',
      'other': '-',
    });
    return '$_temp0';
  }

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonSkip => 'Lewati';

  @override
  String get commonNext => 'Lanjut';

  @override
  String get commonChange => 'Ganti';

  @override
  String get commonUndo => 'Urungkan';

  @override
  String get onboardingWelcomeTitle => 'Selamat datang di Pulang';

  @override
  String get onboardingWelcomeBody =>
      'Catat solat harianmu, pantau hutang qadha, dan lihat konsistensi dari waktu ke waktu. Dua langkah singkat dulu sebelum mulai.';

  @override
  String get onboardingWelcomeCta => 'Mulai';

  @override
  String get onboardingCityTitle => 'Pilih kota kamu';

  @override
  String get onboardingCityBody =>
      'Dipakai untuk menghitung jadwal solat harian. Bisa diganti kapan saja lewat Pengaturan.';

  @override
  String onboardingCitySearchHint(int count) {
    return 'Cari nama kota (min. $count huruf)';
  }

  @override
  String get onboardingCityNotFound => 'Kota tidak ditemukan';

  @override
  String get onboardingNotifTitle => 'Aktifkan pengingat solat';

  @override
  String get onboardingNotifBody =>
      'Pulang mengingatkanmu tepat saat masuk waktu solat. Kamu bisa mengatur ulang ini kapan saja di Pengaturan.';

  @override
  String get onboardingNotifDenied =>
      'Izin belum diberikan. Kamu tetap bisa lanjut — nyalakan lagi lewat Pengaturan kapan pun kamu siap.';

  @override
  String get onboardingNotifEnableCta => 'Aktifkan Notifikasi';

  @override
  String get onboardingNotifActive => 'Notifikasi aktif';

  @override
  String get onboardingNotifDone => 'Selesai';

  @override
  String get onboardingNotifSkipDone => 'Lewati & Selesai';

  @override
  String get commonFollowSystem => 'Ikuti Sistem';

  @override
  String get settingsLanguageTitle => 'Bahasa';

  @override
  String get settingsLanguageDialogTitle => 'Pilih Bahasa';

  @override
  String get settingsLanguageSystemSubtitle =>
      'Otomatis sesuai bahasa perangkat';

  @override
  String get notificationChannelName => 'Jadwal Solat';

  @override
  String get notificationChannelDescription =>
      'Notifikasi saat masuk waktu solat';

  @override
  String notificationPrayerTitle(String prayer) {
    return 'Waktu $prayer';
  }

  @override
  String notificationPrayerBody(String prayer) {
    return 'Sudah masuk waktu $prayer';
  }

  @override
  String get notificationTestTitle => 'Test Notifikasi Terjadwal';

  @override
  String get notificationTestBody =>
      'Jika kamu melihat ini, alarm terjadwal berfungsi.';

  @override
  String get navHome => 'Home';

  @override
  String get navQibla => 'Kiblat';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get homeSettingsBackupWarningTooltip =>
      'Pengaturan — backup Google belum terhubung';

  @override
  String get homeScheduleTitle => 'Jadwal Hari Ini';

  @override
  String homeProgressSemantics(int count) {
    return '$count dari 5 solat selesai';
  }

  @override
  String get homeDefaultCityLabel => 'Pilih Kota';

  @override
  String get homeErrorTitle => 'Gagal memuat jadwal solat';

  @override
  String get homeErrorBody => 'Periksa koneksi internet lalu coba lagi.';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get homeEmptyTitle => 'Jadwal solat tidak tersedia';

  @override
  String get homeEmptyBody =>
      'Pilih kota terlebih dahulu supaya jadwal bisa dimuat.';

  @override
  String get homeChooseCity => 'Pilih kota';

  @override
  String homeDeletedSnackbar(String prayer) {
    return 'Catatan $prayer dihapus.';
  }

  @override
  String get homeNextPrayerLabel => 'Solat Berikutnya';

  @override
  String get homeTimerLoadError => 'Gagal memuat jadwal';

  @override
  String get homeTomorrowSuffix => '(besok)';

  @override
  String get homeCountdownUnknown => 'Waktu tidak\ndiketahui';

  @override
  String get homeCountdownSoon => 'sebentar lagi';

  @override
  String homeCountdownSpokenHm(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours jam',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes menit',
    );
    return '$_temp0 $_temp1 lagi';
  }

  @override
  String homeCountdownSpokenM(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes menit',
    );
    return '$_temp0 lagi';
  }

  @override
  String get homeUnitHourShort => 'j';

  @override
  String get homeUnitMinuteShort => 'm';

  @override
  String get historyTitle => 'Riwayat';

  @override
  String get historyToday => 'Hari Ini';

  @override
  String get historyTabCalendar => 'Kalender';

  @override
  String get historyTabStatistics => 'Ringkasan';

  @override
  String get calendarFormatWeek => 'Minggu';

  @override
  String get calendarFormatMonth => 'Bulan';

  @override
  String get calendarCollapseToWeek => 'Kuncupkan ke tampilan minggu';

  @override
  String get calendarExpandToMonth => 'Perluas ke tampilan bulan';

  @override
  String get calendarLegendOnTime => 'Tepat waktu';

  @override
  String get calendarLegendLate => 'Terlambat';

  @override
  String get calendarLegendMissed => 'Terlewat';

  @override
  String calendarDaySemanticsRecorded(int day, int count) {
    return '$day, $count dari 5 solat tercatat';
  }

  @override
  String calendarIncompleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waktu belum tercatat',
    );
    return '$_temp0';
  }

  @override
  String get calendarIncompleteBody =>
      'Aplikasi tidak menebak — beri tahu apa yang terjadi, atau isi satu-satu lewat daftar di bawah.';

  @override
  String get calendarMarkPrayed => 'Solat';

  @override
  String get calendarMarkMissed => 'Terlewat';

  @override
  String get calendarConfirmMissedTitle => 'Tandai Terlewat?';

  @override
  String get calendarConfirmPrayedTitle => 'Tandai Sudah Solat?';

  @override
  String calendarConfirmMissedBody(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waktu',
    );
    return '$_temp0 pada $date akan dicatat terlewat dan menambah hutang qadha sebanyak $count.';
  }

  @override
  String calendarConfirmPrayedBody(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waktu',
    );
    return '$_temp0 pada $date akan dicatat sudah dikerjakan.';
  }

  @override
  String get calendarConfirmMissedCta => 'Ya, terlewat';

  @override
  String get calendarConfirmPrayedCta => 'Ya, sudah';

  @override
  String calendarMarkedMissedSnackbar(String date) {
    return '$date dicatat terlewat.';
  }

  @override
  String calendarMarkedPrayedSnackbar(String date) {
    return '$date dicatat sudah dikerjakan.';
  }

  @override
  String calendarDeletedSnackbar(String prayer, String date) {
    return 'Catatan $prayer $date dihapus.';
  }

  @override
  String get calendarStatusPerfect => '5/5 Sempurna';

  @override
  String get calendarStatusEmpty => 'Belum ada data';

  @override
  String calendarStatusRecorded(int count) {
    return '$count/5 Tercatat';
  }

  @override
  String get statsSectionBreakdown => 'Rincian per Waktu';

  @override
  String statsSince(String date) {
    return 'Sejak $date';
  }

  @override
  String get statsConsistencySemantics => 'Konsistensi sepanjang riwayat';

  @override
  String statsPercentSemantics(String percent) {
    return '$percent persen';
  }

  @override
  String statsFulfilledSummary(int fulfilled, int known, int days) {
    return '$fulfilled dari $known solat tercatat sudah dikerjakan · $days hari';
  }

  @override
  String statsStreak(int current, int longest) {
    return 'Streak $current hari · terpanjang $longest hari';
  }

  @override
  String statsWeakestInsight(String prayer, int count) {
    return '$prayer paling sering terlewat — $count kali belum diqadha.';
  }

  @override
  String statsUnrecordedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count hari tidak pernah tercatat dan tidak dihitung sebagai hutang.',
    );
    return '$_temp0';
  }

  @override
  String statsErrorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get statsEmptyTitle => 'Belum ada statistik';

  @override
  String get statsEmptyBody =>
      'Catat solatmu di Home untuk melihat konsistensi dan streak di sini.';

  @override
  String get qadhaOutstandingTitle => 'Belum diqadha';

  @override
  String get qadhaOutstandingUnit => 'solat';

  @override
  String qadhaRecordedSince(String date) {
    return 'Tercatat sejak $date';
  }

  @override
  String get qadhaPayAllCta => 'Lunas semua';

  @override
  String get qadhaConfirmOneTitle => 'Tandai lunas?';

  @override
  String qadhaConfirmOneBody(String prayer, String date) {
    return '$prayer $date akan ditandai lunas.';
  }

  @override
  String get qadhaConfirmAllTitle => 'Tandai semua lunas?';

  @override
  String qadhaConfirmAllBody(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hutang solat',
    );
    return '$_temp0 $date akan ditandai lunas sekaligus.';
  }

  @override
  String get qadhaConfirmCta => 'Ya, lunas';

  @override
  String qadhaPaidOneSnackbar(String prayer, String date) {
    return '$prayer $date lunas.';
  }

  @override
  String qadhaPaidAllSnackbar(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count qadha',
    );
    return '$_temp0 $date lunas.';
  }

  @override
  String get qadhaNoDebt => 'Tidak ada hutang solat';

  @override
  String qadhaUnconfirmedDaysRow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari belum tercatat',
    );
    return '$_temp0';
  }

  @override
  String qadhaErrorPrefix(String message) {
    return 'Gagal memuat data qadha: $message';
  }

  @override
  String get qadhaEmptyTitle => 'Belum ada catatan';

  @override
  String get qadhaEmptyBody =>
      'Mulai catat solatmu di Home. Hutang qadha dihitung sejak catatan pertama, dan hanya dari solat yang kamu tandai terlewat.';

  @override
  String get qiblaTitle => 'Kiblat';

  @override
  String get qiblaNoSensor =>
      'Perangkat Anda tidak memiliki sensor kompas (magnetometer).';

  @override
  String get qiblaLocationDisabled =>
      'Layanan lokasi mati. Aktifkan GPS lalu coba lagi.';

  @override
  String get qiblaPermissionDenied =>
      'Izin lokasi diperlukan untuk menentukan arah kiblat.';

  @override
  String get qiblaPermissionDeniedForever =>
      'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan aplikasi.';

  @override
  String get qiblaOpenSettings => 'Buka Pengaturan';

  @override
  String get qiblaSensorError =>
      'Gagal membaca sensor kompas. Coba jauhkan perangkat dari benda logam atau magnet, lalu buka ulang halaman.';

  @override
  String get qiblaWaitingSensor => 'Menunggu data sensor kompas...';

  @override
  String get qiblaFacingQibla => 'Anda menghadap kiblat';

  @override
  String get qiblaTurnToArrow => 'Putar perangkat ke arah panah';

  @override
  String get qiblaCompassSemantics => 'Kompas kiblat';

  @override
  String qiblaDirectionSemantics(String degrees, String status) {
    return 'Arah kiblat $degrees, $status';
  }

  @override
  String get qiblaNotAlignedSemantics =>
      'belum sejajar, putar perangkat ke arah panah';

  @override
  String get qiblaDirectionLabel => 'Arah kiblat';

  @override
  String qiblaCardinalName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'U': 'Utara',
      'TL': 'Timur Laut',
      'T': 'Timur',
      'TG': 'Tenggara',
      'S': 'Selatan',
      'BD': 'Barat Daya',
      'B': 'Barat',
      'BL': 'Barat Laut',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String qiblaDialLabel(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'U': 'U',
      'TL': 'TL',
      'T': 'T',
      'TG': 'TG',
      'S': 'S',
      'BD': 'BD',
      'B': 'B',
      'BL': 'BL',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsNeverBackedUp => 'Belum pernah backup';

  @override
  String get settingsNoCitySelected => 'Belum pilih kota';

  @override
  String get settingsLocationSubtitle => 'Digunakan untuk jadwal solat';

  @override
  String get settingsNotifTitle => 'Aktifkan Notifikasi';

  @override
  String get settingsNotifSubtitle => 'Notifikasi saat masuk waktu solat';

  @override
  String get settingsNotifBlockedBanner =>
      'Izin notifikasi ditolak di sistem — pengingat tidak akan muncul walau opsi ini aktif.';

  @override
  String get settingsRequestPermissionAgain => 'Minta Izin Lagi';

  @override
  String get settingsThemeModeTitle => 'Mode Tampilan';

  @override
  String get settingsThemeLight => 'Mode Terang';

  @override
  String get settingsThemeDark => 'Mode Gelap';

  @override
  String get settingsThemeDialogTitle => 'Pilih Mode Tampilan';

  @override
  String get settingsThemeSystemSubtitle =>
      'Otomatis sesuai pengaturan perangkat';

  @override
  String get settingsThemeLightSubtitle => 'Tampilan cerah untuk siang hari';

  @override
  String get settingsThemeDarkSubtitle => 'Tampilan gelap untuk malam hari';

  @override
  String get settingsBackupSectionTitle => 'Backup & Data';

  @override
  String get settingsGoogleNotLoggedIn => 'Belum Login Google';

  @override
  String get settingsGoogleLoginSubtitle => 'Untuk backup ke Google Drive';

  @override
  String get settingsSigningOut => 'Keluar dari akun...';

  @override
  String settingsSignOutFailed(String error) {
    return 'Gagal keluar: $error';
  }

  @override
  String get settingsAutoBackupTitle => 'Auto Backup';

  @override
  String get settingsAutoBackupSubtitle => 'Backup otomatis ke Google Drive';

  @override
  String get settingsBackupDataTitle => 'Backup Data';

  @override
  String settingsBackupDataSubtitle(String date) {
    return 'Terakhir: $date';
  }

  @override
  String get settingsRestoreDataTitle => 'Restore Data';

  @override
  String get settingsRestoreDataSubtitle => 'Kembalikan data dari Google Drive';

  @override
  String get settingsConnectingGoogle => 'Menghubungkan ke Google...';

  @override
  String get settingsLoginSuccessNoBackup =>
      'Login berhasil. Belum ada backup untuk dipulihkan.';

  @override
  String get settingsLoginSuccessKeptLocal =>
      'Login berhasil. Data lokal dipertahankan.';

  @override
  String get settingsRestoringLatest => 'Memulihkan data backup terbaru...';

  @override
  String get settingsLoginRestoredSuccess =>
      'Login berhasil & data backup terbaru dipulihkan!';

  @override
  String settingsSignInFailed(String error) {
    return 'Gagal masuk: $error';
  }

  @override
  String get settingsRestoreOnLoginTitle => 'Pulihkan Data Backup?';

  @override
  String get settingsRestoreOnLoginBody =>
      'Login berhasil. Kamu sudah punya data di perangkat ini. Memulihkan backup terbaru akan MENIMPA data tersebut. Lanjutkan?';

  @override
  String get settingsKeepLocalData => 'Pertahankan Data';

  @override
  String get settingsRestoreCta => 'Pulihkan';

  @override
  String get settingsBackupNowTitle => 'Backup Sekarang?';

  @override
  String get settingsBackupNowBody =>
      'Data kamu akan disimpan ke Google Drive.';

  @override
  String get settingsBackupCta => 'Backup';

  @override
  String get settingsBackingUp => 'Sedang melakukan backup...';

  @override
  String get settingsBackupSuccess => 'Backup berhasil!';

  @override
  String settingsBackupFailed(String error) {
    return 'Gagal backup: $error';
  }

  @override
  String get settingsLoadingBackupList => 'Memuat daftar backup...';

  @override
  String get settingsChooseBackupTitle => 'Pilih Backup untuk Dipulihkan';

  @override
  String get settingsNoBackupsSaved => 'Belum ada backup tersimpan.';

  @override
  String get settingsUnknownDate => 'Tanggal tidak diketahui';

  @override
  String get settingsLatestBadge => 'Terbaru';

  @override
  String get settingsDeleteBackupTooltip => 'Hapus backup';

  @override
  String get settingsDeleteBackupTitle => 'Hapus Backup?';

  @override
  String settingsDeleteBackupBody(String date) {
    return 'Backup $date akan dihapus permanen dari Google Drive.';
  }

  @override
  String get settingsDeleteCta => 'Hapus';

  @override
  String get settingsBackupDeleted => 'Backup dihapus.';

  @override
  String settingsDeleteFailed(String error) {
    return 'Gagal menghapus: $error';
  }

  @override
  String settingsListBackupFailed(String error) {
    return 'Gagal mengambil list backup: $error';
  }

  @override
  String get settingsRestoreConfirmTitle => 'Restore Data?';

  @override
  String get settingsRestoreConfirmBody =>
      'PERINGATAN: Tindakan ini akan MENIMPA data yang ada sekarang dengan data dari backup. Lanjutkan?';

  @override
  String get settingsRestoringData => 'Sedang memulihkan data...';

  @override
  String get settingsRestoreSuccess => 'Data berhasil di-restore!';

  @override
  String settingsRestoreFailed(String error) {
    return 'Gagal restore: $error';
  }

  @override
  String get settingsAppVersionTitle => 'Versi Aplikasi';

  @override
  String get settingsResetDataTitle => 'Reset Data';

  @override
  String get settingsResetDataSubtitle =>
      'Hapus data di perangkat (backup Drive tetap aman)';

  @override
  String get settingsResetConfirmTitle => 'Reset Data?';

  @override
  String get settingsResetConfirmBody =>
      'Ini akan menghapus SEMUA data solat dan setting di perangkat ini. Backup di Google Drive TIDAK ikut terhapus, jadi data masih bisa dipulihkan lewat Restore. Tindakan ini tidak bisa dibatalkan.';

  @override
  String get settingsResetCta => 'Reset';

  @override
  String get settingsResetting => 'Mereset data...';

  @override
  String get settingsResetSuccess => 'Data berhasil direset';

  @override
  String settingsResetFailed(String error) {
    return 'Gagal reset data: $error';
  }

  @override
  String settingsCityChanged(String city) {
    return 'Kota diubah ke $city';
  }

  @override
  String get settingsCitySearchTitle => 'Cari Kota';

  @override
  String settingsCitySearchHint(int count) {
    return 'Masukkan nama kota (min. $count huruf)';
  }

  @override
  String get settingsCitySearchTooltip => 'Cari';

  @override
  String settingsCitySearchMinChars(int count) {
    return 'Ketik minimal $count huruf.';
  }

  @override
  String checkinEditTitle(String prayer) {
    return 'Edit $prayer';
  }

  @override
  String checkinRecordTitle(String prayer) {
    return 'Catat $prayer';
  }

  @override
  String get checkinDeleteTooltip => 'Hapus catatan';

  @override
  String get checkinOnTimeTitle => 'Tepat Waktu';

  @override
  String get checkinOnTimeSubtitle => 'Solat dilakukan di awal waktu';

  @override
  String get checkinLateTitle => 'Qadha / Terlambat';

  @override
  String get checkinLateSubtitle => 'Solat dilakukan di luar waktu';

  @override
  String get checkinMissedTitle => 'Terlewat';

  @override
  String get checkinMissedSubtitle => 'Tidak solat';

  @override
  String get prayerCardNotRecorded => 'Belum dicatat';

  @override
  String prayerCardStatusSemantics(String status) {
    return 'Status: $status';
  }

  @override
  String get unconfirmedDaysPickerTitle =>
      'Pilih tanggal untuk membukanya di Kalender';
}
