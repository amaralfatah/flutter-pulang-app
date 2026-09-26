import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'Pulang - Presensi Solat'**
  String get appTitle;

  /// No description provided for @prayerName.
  ///
  /// In id, this message translates to:
  /// **'{name, select, subuh{Subuh} dzuhur{Dzuhur} ashar{Ashar} maghrib{Maghrib} isya{Isya} other{-}}'**
  String prayerName(String name);

  /// No description provided for @commonClose.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get commonClose;

  /// No description provided for @commonCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get commonCancel;

  /// No description provided for @commonSkip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get commonSkip;

  /// No description provided for @commonNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get commonNext;

  /// No description provided for @commonChange.
  ///
  /// In id, this message translates to:
  /// **'Ganti'**
  String get commonChange;

  /// No description provided for @commonUndo.
  ///
  /// In id, this message translates to:
  /// **'Urungkan'**
  String get commonUndo;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In id, this message translates to:
  /// **'Selamat datang di Pulang'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In id, this message translates to:
  /// **'Catat solat harianmu, pantau hutang qadha, dan lihat konsistensi dari waktu ke waktu. Dua langkah singkat dulu sebelum mulai.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingWelcomeCta.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get onboardingWelcomeCta;

  /// No description provided for @onboardingCityTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih kota kamu'**
  String get onboardingCityTitle;

  /// No description provided for @onboardingCityBody.
  ///
  /// In id, this message translates to:
  /// **'Dipakai untuk menghitung jadwal solat harian. Bisa diganti kapan saja lewat Pengaturan.'**
  String get onboardingCityBody;

  /// No description provided for @onboardingCitySearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama kota (min. {count} huruf)'**
  String onboardingCitySearchHint(int count);

  /// No description provided for @onboardingCityNotFound.
  ///
  /// In id, this message translates to:
  /// **'Kota tidak ditemukan'**
  String get onboardingCityNotFound;

  /// No description provided for @onboardingNotifTitle.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan pengingat solat'**
  String get onboardingNotifTitle;

  /// No description provided for @onboardingNotifBody.
  ///
  /// In id, this message translates to:
  /// **'Pulang mengingatkanmu tepat saat masuk waktu solat. Kamu bisa mengatur ulang ini kapan saja di Pengaturan.'**
  String get onboardingNotifBody;

  /// No description provided for @onboardingNotifDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin belum diberikan. Kamu tetap bisa lanjut — nyalakan lagi lewat Pengaturan kapan pun kamu siap.'**
  String get onboardingNotifDenied;

  /// No description provided for @onboardingNotifEnableCta.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan Notifikasi'**
  String get onboardingNotifEnableCta;

  /// No description provided for @onboardingNotifActive.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi aktif'**
  String get onboardingNotifActive;

  /// No description provided for @onboardingNotifDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get onboardingNotifDone;

  /// No description provided for @onboardingNotifSkipDone.
  ///
  /// In id, this message translates to:
  /// **'Lewati & Selesai'**
  String get onboardingNotifSkipDone;

  /// No description provided for @commonFollowSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti Sistem'**
  String get commonFollowSystem;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageDialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Bahasa'**
  String get settingsLanguageDialogTitle;

  /// No description provided for @settingsLanguageSystemSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Otomatis sesuai bahasa perangkat'**
  String get settingsLanguageSystemSubtitle;

  /// No description provided for @notificationChannelName.
  ///
  /// In id, this message translates to:
  /// **'Jadwal Solat'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi saat masuk waktu solat'**
  String get notificationChannelDescription;

  /// No description provided for @notificationPrayerTitle.
  ///
  /// In id, this message translates to:
  /// **'Waktu {prayer}'**
  String notificationPrayerTitle(String prayer);

  /// No description provided for @notificationPrayerBody.
  ///
  /// In id, this message translates to:
  /// **'Sudah masuk waktu {prayer}'**
  String notificationPrayerBody(String prayer);

  /// No description provided for @notificationTestTitle.
  ///
  /// In id, this message translates to:
  /// **'Test Notifikasi Terjadwal'**
  String get notificationTestTitle;

  /// No description provided for @notificationTestBody.
  ///
  /// In id, this message translates to:
  /// **'Jika kamu melihat ini, alarm terjadwal berfungsi.'**
  String get notificationTestBody;

  /// No description provided for @navHome.
  ///
  /// In id, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navQibla.
  ///
  /// In id, this message translates to:
  /// **'Kiblat'**
  String get navQibla;

  /// No description provided for @navSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get navSettings;

  /// No description provided for @homeSettingsBackupWarningTooltip.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan — backup Google belum terhubung'**
  String get homeSettingsBackupWarningTooltip;

  /// No description provided for @homeScheduleTitle.
  ///
  /// In id, this message translates to:
  /// **'Jadwal Hari Ini'**
  String get homeScheduleTitle;

  /// No description provided for @homeProgressSemantics.
  ///
  /// In id, this message translates to:
  /// **'{count} dari 5 solat selesai'**
  String homeProgressSemantics(int count);

  /// No description provided for @homeDefaultCityLabel.
  ///
  /// In id, this message translates to:
  /// **'Pilih Kota'**
  String get homeDefaultCityLabel;

  /// No description provided for @homeErrorTitle.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat jadwal solat'**
  String get homeErrorTitle;

  /// No description provided for @homeErrorBody.
  ///
  /// In id, this message translates to:
  /// **'Periksa koneksi internet lalu coba lagi.'**
  String get homeErrorBody;

  /// No description provided for @commonRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get commonRetry;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Jadwal solat tidak tersedia'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Pilih kota terlebih dahulu supaya jadwal bisa dimuat.'**
  String get homeEmptyBody;

  /// No description provided for @homeChooseCity.
  ///
  /// In id, this message translates to:
  /// **'Pilih kota'**
  String get homeChooseCity;

  /// No description provided for @homeDeletedSnackbar.
  ///
  /// In id, this message translates to:
  /// **'Catatan {prayer} dihapus.'**
  String homeDeletedSnackbar(String prayer);

  /// No description provided for @homeNextPrayerLabel.
  ///
  /// In id, this message translates to:
  /// **'Solat Berikutnya'**
  String get homeNextPrayerLabel;

  /// No description provided for @homeTimerLoadError.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat jadwal'**
  String get homeTimerLoadError;

  /// No description provided for @homeTomorrowSuffix.
  ///
  /// In id, this message translates to:
  /// **'(besok)'**
  String get homeTomorrowSuffix;

  /// No description provided for @homeCountdownUnknown.
  ///
  /// In id, this message translates to:
  /// **'Waktu tidak\ndiketahui'**
  String get homeCountdownUnknown;

  /// No description provided for @homeCountdownSoon.
  ///
  /// In id, this message translates to:
  /// **'sebentar lagi'**
  String get homeCountdownSoon;

  /// No description provided for @homeCountdownSpokenHm.
  ///
  /// In id, this message translates to:
  /// **'{hours, plural, other{{hours} jam}} {minutes, plural, other{{minutes} menit}} lagi'**
  String homeCountdownSpokenHm(int hours, int minutes);

  /// No description provided for @homeCountdownSpokenM.
  ///
  /// In id, this message translates to:
  /// **'{minutes, plural, other{{minutes} menit}} lagi'**
  String homeCountdownSpokenM(int minutes);

  /// No description provided for @homeUnitHourShort.
  ///
  /// In id, this message translates to:
  /// **'j'**
  String get homeUnitHourShort;

  /// No description provided for @homeUnitMinuteShort.
  ///
  /// In id, this message translates to:
  /// **'m'**
  String get homeUnitMinuteShort;

  /// No description provided for @historyTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat'**
  String get historyTitle;

  /// No description provided for @historyToday.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get historyToday;

  /// No description provided for @historyTabCalendar.
  ///
  /// In id, this message translates to:
  /// **'Kalender'**
  String get historyTabCalendar;

  /// No description provided for @historyTabStatistics.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan'**
  String get historyTabStatistics;

  /// No description provided for @calendarFormatWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu'**
  String get calendarFormatWeek;

  /// No description provided for @calendarFormatMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan'**
  String get calendarFormatMonth;

  /// No description provided for @calendarCollapseToWeek.
  ///
  /// In id, this message translates to:
  /// **'Kuncupkan ke tampilan minggu'**
  String get calendarCollapseToWeek;

  /// No description provided for @calendarExpandToMonth.
  ///
  /// In id, this message translates to:
  /// **'Perluas ke tampilan bulan'**
  String get calendarExpandToMonth;

  /// No description provided for @calendarLegendOnTime.
  ///
  /// In id, this message translates to:
  /// **'Tepat waktu'**
  String get calendarLegendOnTime;

  /// No description provided for @calendarLegendLate.
  ///
  /// In id, this message translates to:
  /// **'Terlambat'**
  String get calendarLegendLate;

  /// No description provided for @calendarLegendMissed.
  ///
  /// In id, this message translates to:
  /// **'Terlewat'**
  String get calendarLegendMissed;

  /// No description provided for @calendarDaySemanticsRecorded.
  ///
  /// In id, this message translates to:
  /// **'{day}, {count} dari 5 solat tercatat'**
  String calendarDaySemanticsRecorded(int day, int count);

  /// No description provided for @calendarIncompleteTitle.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} waktu belum tercatat}}'**
  String calendarIncompleteTitle(int count);

  /// No description provided for @calendarIncompleteBody.
  ///
  /// In id, this message translates to:
  /// **'Aplikasi tidak menebak — beri tahu apa yang terjadi, atau isi satu-satu lewat daftar di bawah.'**
  String get calendarIncompleteBody;

  /// No description provided for @calendarMarkPrayed.
  ///
  /// In id, this message translates to:
  /// **'Solat'**
  String get calendarMarkPrayed;

  /// No description provided for @calendarMarkMissed.
  ///
  /// In id, this message translates to:
  /// **'Terlewat'**
  String get calendarMarkMissed;

  /// No description provided for @calendarConfirmMissedTitle.
  ///
  /// In id, this message translates to:
  /// **'Tandai Terlewat?'**
  String get calendarConfirmMissedTitle;

  /// No description provided for @calendarConfirmPrayedTitle.
  ///
  /// In id, this message translates to:
  /// **'Tandai Sudah Solat?'**
  String get calendarConfirmPrayedTitle;

  /// No description provided for @calendarConfirmMissedBody.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} waktu}} pada {date} akan dicatat terlewat dan menambah hutang qadha sebanyak {count}.'**
  String calendarConfirmMissedBody(int count, String date);

  /// No description provided for @calendarConfirmPrayedBody.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} waktu}} pada {date} akan dicatat sudah dikerjakan.'**
  String calendarConfirmPrayedBody(int count, String date);

  /// No description provided for @calendarConfirmMissedCta.
  ///
  /// In id, this message translates to:
  /// **'Ya, terlewat'**
  String get calendarConfirmMissedCta;

  /// No description provided for @calendarConfirmPrayedCta.
  ///
  /// In id, this message translates to:
  /// **'Ya, sudah'**
  String get calendarConfirmPrayedCta;

  /// No description provided for @calendarMarkedMissedSnackbar.
  ///
  /// In id, this message translates to:
  /// **'{date} dicatat terlewat.'**
  String calendarMarkedMissedSnackbar(String date);

  /// No description provided for @calendarMarkedPrayedSnackbar.
  ///
  /// In id, this message translates to:
  /// **'{date} dicatat sudah dikerjakan.'**
  String calendarMarkedPrayedSnackbar(String date);

  /// No description provided for @calendarDeletedSnackbar.
  ///
  /// In id, this message translates to:
  /// **'Catatan {prayer} {date} dihapus.'**
  String calendarDeletedSnackbar(String prayer, String date);

  /// No description provided for @calendarStatusPerfect.
  ///
  /// In id, this message translates to:
  /// **'5/5 Sempurna'**
  String get calendarStatusPerfect;

  /// No description provided for @calendarStatusEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data'**
  String get calendarStatusEmpty;

  /// No description provided for @calendarStatusRecorded.
  ///
  /// In id, this message translates to:
  /// **'{count}/5 Tercatat'**
  String calendarStatusRecorded(int count);

  /// No description provided for @statsSectionBreakdown.
  ///
  /// In id, this message translates to:
  /// **'Rincian per Waktu'**
  String get statsSectionBreakdown;

  /// No description provided for @statsSince.
  ///
  /// In id, this message translates to:
  /// **'Sejak {date}'**
  String statsSince(String date);

  /// No description provided for @statsConsistencySemantics.
  ///
  /// In id, this message translates to:
  /// **'Konsistensi sepanjang riwayat'**
  String get statsConsistencySemantics;

  /// No description provided for @statsPercentSemantics.
  ///
  /// In id, this message translates to:
  /// **'{percent} persen'**
  String statsPercentSemantics(String percent);

  /// No description provided for @statsFulfilledSummary.
  ///
  /// In id, this message translates to:
  /// **'{fulfilled} dari {known} solat tercatat sudah dikerjakan · {days} hari'**
  String statsFulfilledSummary(int fulfilled, int known, int days);

  /// No description provided for @statsStreak.
  ///
  /// In id, this message translates to:
  /// **'Streak {current} hari · terpanjang {longest} hari'**
  String statsStreak(int current, int longest);

  /// No description provided for @statsWeakestInsight.
  ///
  /// In id, this message translates to:
  /// **'{prayer} paling sering terlewat — {count} kali belum diqadha.'**
  String statsWeakestInsight(String prayer, int count);

  /// No description provided for @statsUnrecordedNote.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} hari tidak pernah tercatat dan tidak dihitung sebagai hutang.}}'**
  String statsUnrecordedNote(int count);

  /// No description provided for @statsErrorPrefix.
  ///
  /// In id, this message translates to:
  /// **'Error: {message}'**
  String statsErrorPrefix(String message);

  /// No description provided for @statsEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada statistik'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Catat solatmu di Home untuk melihat konsistensi dan streak di sini.'**
  String get statsEmptyBody;

  /// No description provided for @qadhaOutstandingTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum diqadha'**
  String get qadhaOutstandingTitle;

  /// No description provided for @qadhaOutstandingUnit.
  ///
  /// In id, this message translates to:
  /// **'solat'**
  String get qadhaOutstandingUnit;

  /// No description provided for @qadhaRecordedSince.
  ///
  /// In id, this message translates to:
  /// **'Tercatat sejak {date}'**
  String qadhaRecordedSince(String date);

  /// No description provided for @qadhaPayAllCta.
  ///
  /// In id, this message translates to:
  /// **'Lunas semua'**
  String get qadhaPayAllCta;

  /// No description provided for @qadhaConfirmOneTitle.
  ///
  /// In id, this message translates to:
  /// **'Tandai lunas?'**
  String get qadhaConfirmOneTitle;

  /// No description provided for @qadhaConfirmOneBody.
  ///
  /// In id, this message translates to:
  /// **'{prayer} {date} akan ditandai lunas.'**
  String qadhaConfirmOneBody(String prayer, String date);

  /// No description provided for @qadhaConfirmAllTitle.
  ///
  /// In id, this message translates to:
  /// **'Tandai semua lunas?'**
  String get qadhaConfirmAllTitle;

  /// No description provided for @qadhaConfirmAllBody.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} hutang solat}} {date} akan ditandai lunas sekaligus.'**
  String qadhaConfirmAllBody(int count, String date);

  /// No description provided for @qadhaConfirmCta.
  ///
  /// In id, this message translates to:
  /// **'Ya, lunas'**
  String get qadhaConfirmCta;

  /// No description provided for @qadhaPaidOneSnackbar.
  ///
  /// In id, this message translates to:
  /// **'{prayer} {date} lunas.'**
  String qadhaPaidOneSnackbar(String prayer, String date);

  /// No description provided for @qadhaPaidAllSnackbar.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} qadha}} {date} lunas.'**
  String qadhaPaidAllSnackbar(int count, String date);

  /// No description provided for @qadhaNoDebt.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada hutang solat'**
  String get qadhaNoDebt;

  /// No description provided for @qadhaUnconfirmedDaysRow.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} hari belum tercatat}}'**
  String qadhaUnconfirmedDaysRow(int count);

  /// No description provided for @qadhaErrorPrefix.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data qadha: {message}'**
  String qadhaErrorPrefix(String message);

  /// No description provided for @qadhaEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan'**
  String get qadhaEmptyTitle;

  /// No description provided for @qadhaEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Mulai catat solatmu di Home. Hutang qadha dihitung sejak catatan pertama, dan hanya dari solat yang kamu tandai terlewat.'**
  String get qadhaEmptyBody;

  /// No description provided for @qiblaTitle.
  ///
  /// In id, this message translates to:
  /// **'Kiblat'**
  String get qiblaTitle;

  /// No description provided for @qiblaNoSensor.
  ///
  /// In id, this message translates to:
  /// **'Perangkat Anda tidak memiliki sensor kompas (magnetometer).'**
  String get qiblaNoSensor;

  /// No description provided for @qiblaLocationDisabled.
  ///
  /// In id, this message translates to:
  /// **'Layanan lokasi mati. Aktifkan GPS lalu coba lagi.'**
  String get qiblaLocationDisabled;

  /// No description provided for @qiblaPermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin lokasi diperlukan untuk menentukan arah kiblat.'**
  String get qiblaPermissionDenied;

  /// No description provided for @qiblaPermissionDeniedForever.
  ///
  /// In id, this message translates to:
  /// **'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan aplikasi.'**
  String get qiblaPermissionDeniedForever;

  /// No description provided for @qiblaOpenSettings.
  ///
  /// In id, this message translates to:
  /// **'Buka Pengaturan'**
  String get qiblaOpenSettings;

  /// No description provided for @qiblaSensorError.
  ///
  /// In id, this message translates to:
  /// **'Gagal membaca sensor kompas. Coba jauhkan perangkat dari benda logam atau magnet, lalu buka ulang halaman.'**
  String get qiblaSensorError;

  /// No description provided for @qiblaWaitingSensor.
  ///
  /// In id, this message translates to:
  /// **'Menunggu data sensor kompas...'**
  String get qiblaWaitingSensor;

  /// No description provided for @qiblaFacingQibla.
  ///
  /// In id, this message translates to:
  /// **'Anda menghadap kiblat'**
  String get qiblaFacingQibla;

  /// No description provided for @qiblaTurnToArrow.
  ///
  /// In id, this message translates to:
  /// **'Putar perangkat ke arah panah'**
  String get qiblaTurnToArrow;

  /// No description provided for @qiblaCompassSemantics.
  ///
  /// In id, this message translates to:
  /// **'Kompas kiblat'**
  String get qiblaCompassSemantics;

  /// No description provided for @qiblaDirectionSemantics.
  ///
  /// In id, this message translates to:
  /// **'Arah kiblat {degrees}, {status}'**
  String qiblaDirectionSemantics(String degrees, String status);

  /// No description provided for @qiblaNotAlignedSemantics.
  ///
  /// In id, this message translates to:
  /// **'belum sejajar, putar perangkat ke arah panah'**
  String get qiblaNotAlignedSemantics;

  /// No description provided for @qiblaDirectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Arah kiblat'**
  String get qiblaDirectionLabel;

  /// No description provided for @qiblaCardinalName.
  ///
  /// In id, this message translates to:
  /// **'{code, select, U{Utara} TL{Timur Laut} T{Timur} TG{Tenggara} S{Selatan} BD{Barat Daya} B{Barat} BL{Barat Laut} other{{code}}}'**
  String qiblaCardinalName(String code);

  /// No description provided for @qiblaDialLabel.
  ///
  /// In id, this message translates to:
  /// **'{code, select, U{U} TL{TL} T{T} TG{TG} S{S} BD{BD} B{B} BL{BL} other{{code}}}'**
  String qiblaDialLabel(String code);

  /// No description provided for @settingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settingsTitle;

  /// No description provided for @settingsNeverBackedUp.
  ///
  /// In id, this message translates to:
  /// **'Belum pernah backup'**
  String get settingsNeverBackedUp;

  /// No description provided for @settingsNoCitySelected.
  ///
  /// In id, this message translates to:
  /// **'Belum pilih kota'**
  String get settingsNoCitySelected;

  /// No description provided for @settingsLocationSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Digunakan untuk jadwal solat'**
  String get settingsLocationSubtitle;

  /// No description provided for @settingsNotifTitle.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan Notifikasi'**
  String get settingsNotifTitle;

  /// No description provided for @settingsNotifSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi saat masuk waktu solat'**
  String get settingsNotifSubtitle;

  /// No description provided for @settingsNotifBlockedBanner.
  ///
  /// In id, this message translates to:
  /// **'Izin notifikasi ditolak di sistem — pengingat tidak akan muncul walau opsi ini aktif.'**
  String get settingsNotifBlockedBanner;

  /// No description provided for @settingsRequestPermissionAgain.
  ///
  /// In id, this message translates to:
  /// **'Minta Izin Lagi'**
  String get settingsRequestPermissionAgain;

  /// No description provided for @settingsThemeModeTitle.
  ///
  /// In id, this message translates to:
  /// **'Mode Tampilan'**
  String get settingsThemeModeTitle;

  /// No description provided for @settingsThemeLight.
  ///
  /// In id, this message translates to:
  /// **'Mode Terang'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In id, this message translates to:
  /// **'Mode Gelap'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeDialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Mode Tampilan'**
  String get settingsThemeDialogTitle;

  /// No description provided for @settingsThemeSystemSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Otomatis sesuai pengaturan perangkat'**
  String get settingsThemeSystemSubtitle;

  /// No description provided for @settingsThemeLightSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Tampilan cerah untuk siang hari'**
  String get settingsThemeLightSubtitle;

  /// No description provided for @settingsThemeDarkSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Tampilan gelap untuk malam hari'**
  String get settingsThemeDarkSubtitle;

  /// No description provided for @settingsBackupSectionTitle.
  ///
  /// In id, this message translates to:
  /// **'Backup & Data'**
  String get settingsBackupSectionTitle;

  /// No description provided for @settingsGoogleNotLoggedIn.
  ///
  /// In id, this message translates to:
  /// **'Belum Login Google'**
  String get settingsGoogleNotLoggedIn;

  /// No description provided for @settingsGoogleLoginSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Untuk backup ke Google Drive'**
  String get settingsGoogleLoginSubtitle;

  /// No description provided for @settingsSigningOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun...'**
  String get settingsSigningOut;

  /// No description provided for @settingsSignOutFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal keluar: {error}'**
  String settingsSignOutFailed(String error);

  /// No description provided for @settingsAutoBackupTitle.
  ///
  /// In id, this message translates to:
  /// **'Auto Backup'**
  String get settingsAutoBackupTitle;

  /// No description provided for @settingsAutoBackupSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Backup otomatis ke Google Drive'**
  String get settingsAutoBackupSubtitle;

  /// No description provided for @settingsBackupDataTitle.
  ///
  /// In id, this message translates to:
  /// **'Backup Data'**
  String get settingsBackupDataTitle;

  /// No description provided for @settingsBackupDataSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Terakhir: {date}'**
  String settingsBackupDataSubtitle(String date);

  /// No description provided for @settingsRestoreDataTitle.
  ///
  /// In id, this message translates to:
  /// **'Restore Data'**
  String get settingsRestoreDataTitle;

  /// No description provided for @settingsRestoreDataSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Kembalikan data dari Google Drive'**
  String get settingsRestoreDataSubtitle;

  /// No description provided for @settingsConnectingGoogle.
  ///
  /// In id, this message translates to:
  /// **'Menghubungkan ke Google...'**
  String get settingsConnectingGoogle;

  /// No description provided for @settingsLoginSuccessNoBackup.
  ///
  /// In id, this message translates to:
  /// **'Login berhasil. Belum ada backup untuk dipulihkan.'**
  String get settingsLoginSuccessNoBackup;

  /// No description provided for @settingsLoginSuccessKeptLocal.
  ///
  /// In id, this message translates to:
  /// **'Login berhasil. Data lokal dipertahankan.'**
  String get settingsLoginSuccessKeptLocal;

  /// No description provided for @settingsRestoringLatest.
  ///
  /// In id, this message translates to:
  /// **'Memulihkan data backup terbaru...'**
  String get settingsRestoringLatest;

  /// No description provided for @settingsLoginRestoredSuccess.
  ///
  /// In id, this message translates to:
  /// **'Login berhasil & data backup terbaru dipulihkan!'**
  String get settingsLoginRestoredSuccess;

  /// No description provided for @settingsSignInFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal masuk: {error}'**
  String settingsSignInFailed(String error);

  /// No description provided for @settingsRestoreOnLoginTitle.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan Data Backup?'**
  String get settingsRestoreOnLoginTitle;

  /// No description provided for @settingsRestoreOnLoginBody.
  ///
  /// In id, this message translates to:
  /// **'Login berhasil. Kamu sudah punya data di perangkat ini. Memulihkan backup terbaru akan MENIMPA data tersebut. Lanjutkan?'**
  String get settingsRestoreOnLoginBody;

  /// No description provided for @settingsKeepLocalData.
  ///
  /// In id, this message translates to:
  /// **'Pertahankan Data'**
  String get settingsKeepLocalData;

  /// No description provided for @settingsRestoreCta.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan'**
  String get settingsRestoreCta;

  /// No description provided for @settingsBackupNowTitle.
  ///
  /// In id, this message translates to:
  /// **'Backup Sekarang?'**
  String get settingsBackupNowTitle;

  /// No description provided for @settingsBackupNowBody.
  ///
  /// In id, this message translates to:
  /// **'Data kamu akan disimpan ke Google Drive.'**
  String get settingsBackupNowBody;

  /// No description provided for @settingsBackupCta.
  ///
  /// In id, this message translates to:
  /// **'Backup'**
  String get settingsBackupCta;

  /// No description provided for @settingsBackingUp.
  ///
  /// In id, this message translates to:
  /// **'Sedang melakukan backup...'**
  String get settingsBackingUp;

  /// No description provided for @settingsBackupSuccess.
  ///
  /// In id, this message translates to:
  /// **'Backup berhasil!'**
  String get settingsBackupSuccess;

  /// No description provided for @settingsBackupFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal backup: {error}'**
  String settingsBackupFailed(String error);

  /// No description provided for @settingsLoadingBackupList.
  ///
  /// In id, this message translates to:
  /// **'Memuat daftar backup...'**
  String get settingsLoadingBackupList;

  /// No description provided for @settingsChooseBackupTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Backup untuk Dipulihkan'**
  String get settingsChooseBackupTitle;

  /// No description provided for @settingsNoBackupsSaved.
  ///
  /// In id, this message translates to:
  /// **'Belum ada backup tersimpan.'**
  String get settingsNoBackupsSaved;

  /// No description provided for @settingsUnknownDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal tidak diketahui'**
  String get settingsUnknownDate;

  /// No description provided for @settingsLatestBadge.
  ///
  /// In id, this message translates to:
  /// **'Terbaru'**
  String get settingsLatestBadge;

  /// No description provided for @settingsDeleteBackupTooltip.
  ///
  /// In id, this message translates to:
  /// **'Hapus backup'**
  String get settingsDeleteBackupTooltip;

  /// No description provided for @settingsDeleteBackupTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus Backup?'**
  String get settingsDeleteBackupTitle;

  /// No description provided for @settingsDeleteBackupBody.
  ///
  /// In id, this message translates to:
  /// **'Backup {date} akan dihapus permanen dari Google Drive.'**
  String settingsDeleteBackupBody(String date);

  /// No description provided for @settingsDeleteCta.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get settingsDeleteCta;

  /// No description provided for @settingsBackupDeleted.
  ///
  /// In id, this message translates to:
  /// **'Backup dihapus.'**
  String get settingsBackupDeleted;

  /// No description provided for @settingsDeleteFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus: {error}'**
  String settingsDeleteFailed(String error);

  /// No description provided for @settingsListBackupFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengambil list backup: {error}'**
  String settingsListBackupFailed(String error);

  /// No description provided for @settingsRestoreConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Restore Data?'**
  String get settingsRestoreConfirmTitle;

  /// No description provided for @settingsRestoreConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'PERINGATAN: Tindakan ini akan MENIMPA data yang ada sekarang dengan data dari backup. Lanjutkan?'**
  String get settingsRestoreConfirmBody;

  /// No description provided for @settingsRestoringData.
  ///
  /// In id, this message translates to:
  /// **'Sedang memulihkan data...'**
  String get settingsRestoringData;

  /// No description provided for @settingsRestoreSuccess.
  ///
  /// In id, this message translates to:
  /// **'Data berhasil di-restore!'**
  String get settingsRestoreSuccess;

  /// No description provided for @settingsRestoreFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal restore: {error}'**
  String settingsRestoreFailed(String error);

  /// No description provided for @settingsAppVersionTitle.
  ///
  /// In id, this message translates to:
  /// **'Versi Aplikasi'**
  String get settingsAppVersionTitle;

  /// No description provided for @settingsResetDataTitle.
  ///
  /// In id, this message translates to:
  /// **'Reset Data'**
  String get settingsResetDataTitle;

  /// No description provided for @settingsResetDataSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus data di perangkat (backup Drive tetap aman)'**
  String get settingsResetDataSubtitle;

  /// No description provided for @settingsResetConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Reset Data?'**
  String get settingsResetConfirmTitle;

  /// No description provided for @settingsResetConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Ini akan menghapus SEMUA data solat dan setting di perangkat ini. Backup di Google Drive TIDAK ikut terhapus, jadi data masih bisa dipulihkan lewat Restore. Tindakan ini tidak bisa dibatalkan.'**
  String get settingsResetConfirmBody;

  /// No description provided for @settingsResetCta.
  ///
  /// In id, this message translates to:
  /// **'Reset'**
  String get settingsResetCta;

  /// No description provided for @settingsResetting.
  ///
  /// In id, this message translates to:
  /// **'Mereset data...'**
  String get settingsResetting;

  /// No description provided for @settingsResetSuccess.
  ///
  /// In id, this message translates to:
  /// **'Data berhasil direset'**
  String get settingsResetSuccess;

  /// No description provided for @settingsResetFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal reset data: {error}'**
  String settingsResetFailed(String error);

  /// No description provided for @settingsCityChanged.
  ///
  /// In id, this message translates to:
  /// **'Kota diubah ke {city}'**
  String settingsCityChanged(String city);

  /// No description provided for @settingsCitySearchTitle.
  ///
  /// In id, this message translates to:
  /// **'Cari Kota'**
  String get settingsCitySearchTitle;

  /// No description provided for @settingsCitySearchHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan nama kota (min. {count} huruf)'**
  String settingsCitySearchHint(int count);

  /// No description provided for @settingsCitySearchTooltip.
  ///
  /// In id, this message translates to:
  /// **'Cari'**
  String get settingsCitySearchTooltip;

  /// No description provided for @settingsCitySearchMinChars.
  ///
  /// In id, this message translates to:
  /// **'Ketik minimal {count} huruf.'**
  String settingsCitySearchMinChars(int count);

  /// No description provided for @checkinEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit {prayer}'**
  String checkinEditTitle(String prayer);

  /// No description provided for @checkinRecordTitle.
  ///
  /// In id, this message translates to:
  /// **'Catat {prayer}'**
  String checkinRecordTitle(String prayer);

  /// No description provided for @checkinDeleteTooltip.
  ///
  /// In id, this message translates to:
  /// **'Hapus catatan'**
  String get checkinDeleteTooltip;

  /// No description provided for @checkinOnTimeTitle.
  ///
  /// In id, this message translates to:
  /// **'Tepat Waktu'**
  String get checkinOnTimeTitle;

  /// No description provided for @checkinOnTimeSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Solat dilakukan di awal waktu'**
  String get checkinOnTimeSubtitle;

  /// No description provided for @checkinLateTitle.
  ///
  /// In id, this message translates to:
  /// **'Qadha / Terlambat'**
  String get checkinLateTitle;

  /// No description provided for @checkinLateSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Solat dilakukan di luar waktu'**
  String get checkinLateSubtitle;

  /// No description provided for @checkinMissedTitle.
  ///
  /// In id, this message translates to:
  /// **'Terlewat'**
  String get checkinMissedTitle;

  /// No description provided for @checkinMissedSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Tidak solat'**
  String get checkinMissedSubtitle;

  /// No description provided for @prayerCardNotRecorded.
  ///
  /// In id, this message translates to:
  /// **'Belum dicatat'**
  String get prayerCardNotRecorded;

  /// No description provided for @prayerCardStatusSemantics.
  ///
  /// In id, this message translates to:
  /// **'Status: {status}'**
  String prayerCardStatusSemantics(String status);

  /// No description provided for @unconfirmedDaysPickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal untuk membukanya di Kalender'**
  String get unconfirmedDaysPickerTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
