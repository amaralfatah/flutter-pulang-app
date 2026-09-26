// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pulang - Prayer Tracker';

  @override
  String prayerName(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'subuh': 'Fajr',
      'dzuhur': 'Dhuhr',
      'ashar': 'Asr',
      'maghrib': 'Maghrib',
      'isya': 'Isha',
      'other': '-',
    });
    return '$_temp0';
  }

  @override
  String get commonClose => 'Close';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonNext => 'Next';

  @override
  String get commonChange => 'Change';

  @override
  String get commonUndo => 'Undo';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Pulang';

  @override
  String get onboardingWelcomeBody =>
      'Log your daily prayers, track qadha debt, and see your consistency over time. Two quick steps before you start.';

  @override
  String get onboardingWelcomeCta => 'Get Started';

  @override
  String get onboardingCityTitle => 'Choose your city';

  @override
  String get onboardingCityBody =>
      'Used to calculate daily prayer times. You can change it anytime in Settings.';

  @override
  String onboardingCitySearchHint(int count) {
    return 'Search city name (min. $count letters)';
  }

  @override
  String get onboardingCityNotFound => 'City not found';

  @override
  String get onboardingNotifTitle => 'Turn on prayer reminders';

  @override
  String get onboardingNotifBody =>
      'Pulang notifies you right when a prayer time begins. You can change this anytime in Settings.';

  @override
  String get onboardingNotifDenied =>
      'Permission not granted yet. You can still continue — turn it on again in Settings whenever you\'re ready.';

  @override
  String get onboardingNotifEnableCta => 'Enable Notifications';

  @override
  String get onboardingNotifActive => 'Notifications on';

  @override
  String get onboardingNotifDone => 'Done';

  @override
  String get onboardingNotifSkipDone => 'Skip & Finish';

  @override
  String get commonFollowSystem => 'Follow System';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageDialogTitle => 'Choose Language';

  @override
  String get settingsLanguageSystemSubtitle => 'Matches your device language';

  @override
  String get notificationChannelName => 'Prayer Times';

  @override
  String get notificationChannelDescription =>
      'Notifies you when a prayer time begins';

  @override
  String notificationPrayerTitle(String prayer) {
    return '$prayer time';
  }

  @override
  String notificationPrayerBody(String prayer) {
    return 'It\'s now time for $prayer';
  }

  @override
  String get notificationTestTitle => 'Scheduled Notification Test';

  @override
  String get notificationTestBody =>
      'If you see this, scheduled alarms are working.';

  @override
  String get navHome => 'Home';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeSettingsBackupWarningTooltip =>
      'Settings — Google backup not connected';

  @override
  String get homeScheduleTitle => 'Today\'s Schedule';

  @override
  String homeProgressSemantics(int count) {
    return '$count of 5 prayers completed';
  }

  @override
  String get homeDefaultCityLabel => 'Choose City';

  @override
  String get homeErrorTitle => 'Failed to load prayer schedule';

  @override
  String get homeErrorBody => 'Check your internet connection and try again.';

  @override
  String get commonRetry => 'Retry';

  @override
  String get homeEmptyTitle => 'Prayer schedule unavailable';

  @override
  String get homeEmptyBody => 'Choose a city first so the schedule can load.';

  @override
  String get homeChooseCity => 'Choose city';

  @override
  String homeDeletedSnackbar(String prayer) {
    return '$prayer entry deleted.';
  }

  @override
  String get homeNextPrayerLabel => 'Next Prayer';

  @override
  String get homeTimerLoadError => 'Failed to load schedule';

  @override
  String get homeTomorrowSuffix => '(tomorrow)';

  @override
  String get homeCountdownUnknown => 'Time\nunknown';

  @override
  String get homeCountdownSoon => 'in a moment';

  @override
  String homeCountdownSpokenHm(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '$hours hour',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return '$_temp0 $_temp1 left';
  }

  @override
  String homeCountdownSpokenM(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return '$_temp0 left';
  }

  @override
  String get homeUnitHourShort => 'h';

  @override
  String get homeUnitMinuteShort => 'm';

  @override
  String get historyTitle => 'History';

  @override
  String get historyToday => 'Today';

  @override
  String get historyTabCalendar => 'Calendar';

  @override
  String get historyTabStatistics => 'Summary';

  @override
  String get calendarFormatWeek => 'Week';

  @override
  String get calendarFormatMonth => 'Month';

  @override
  String get calendarCollapseToWeek => 'Collapse to week view';

  @override
  String get calendarExpandToMonth => 'Expand to month view';

  @override
  String get calendarLegendOnTime => 'On time';

  @override
  String get calendarLegendLate => 'Late';

  @override
  String get calendarLegendMissed => 'Missed';

  @override
  String calendarDaySemanticsRecorded(int day, int count) {
    return '$day, $count of 5 prayers recorded';
  }

  @override
  String calendarIncompleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times not recorded',
      one: '$count time not recorded',
    );
    return '$_temp0';
  }

  @override
  String get calendarIncompleteBody =>
      'The app doesn\'t guess — tell it what happened, or fill each one in from the list below.';

  @override
  String get calendarMarkPrayed => 'Prayed';

  @override
  String get calendarMarkMissed => 'Missed';

  @override
  String get calendarConfirmMissedTitle => 'Mark as Missed?';

  @override
  String get calendarConfirmPrayedTitle => 'Mark as Prayed?';

  @override
  String calendarConfirmMissedBody(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '$count time',
    );
    return '$_temp0 on $date will be recorded as missed and add $count to your qadha debt.';
  }

  @override
  String calendarConfirmPrayedBody(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '$count time',
    );
    return '$_temp0 on $date will be recorded as prayed.';
  }

  @override
  String get calendarConfirmMissedCta => 'Yes, missed';

  @override
  String get calendarConfirmPrayedCta => 'Yes, prayed';

  @override
  String calendarMarkedMissedSnackbar(String date) {
    return '$date recorded as missed.';
  }

  @override
  String calendarMarkedPrayedSnackbar(String date) {
    return '$date recorded as prayed.';
  }

  @override
  String calendarDeletedSnackbar(String prayer, String date) {
    return '$prayer entry on $date deleted.';
  }

  @override
  String get calendarStatusPerfect => '5/5 Perfect';

  @override
  String get calendarStatusEmpty => 'No data yet';

  @override
  String calendarStatusRecorded(int count) {
    return '$count/5 Recorded';
  }

  @override
  String get statsSectionBreakdown => 'Breakdown by Prayer';

  @override
  String statsSince(String date) {
    return 'Since $date';
  }

  @override
  String get statsConsistencySemantics => 'Consistency across your history';

  @override
  String statsPercentSemantics(String percent) {
    return '$percent percent';
  }

  @override
  String statsFulfilledSummary(int fulfilled, int known, int days) {
    return '$fulfilled of $known recorded prayers fulfilled · $days days';
  }

  @override
  String statsStreak(int current, int longest) {
    return 'Streak $current days · longest $longest days';
  }

  @override
  String statsWeakestInsight(String prayer, int count) {
    return '$prayer is missed most often — $count still unpaid.';
  }

  @override
  String statsUnrecordedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days were never recorded and aren\'t counted as debt.',
      one: '$count day was never recorded and isn\'t counted as debt.',
    );
    return '$_temp0';
  }

  @override
  String statsErrorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get statsEmptyTitle => 'No statistics yet';

  @override
  String get statsEmptyBody =>
      'Log your prayers on Home to see your consistency and streak here.';

  @override
  String get qadhaOutstandingTitle => 'Not yet made up';

  @override
  String get qadhaOutstandingUnit => 'prayers';

  @override
  String qadhaRecordedSince(String date) {
    return 'Recorded since $date';
  }

  @override
  String get qadhaPayAllCta => 'Pay all';

  @override
  String get qadhaConfirmOneTitle => 'Mark as paid?';

  @override
  String qadhaConfirmOneBody(String prayer, String date) {
    return '$prayer on $date will be marked as paid.';
  }

  @override
  String get qadhaConfirmAllTitle => 'Mark all as paid?';

  @override
  String qadhaConfirmAllBody(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prayer debts',
      one: '$count prayer debt',
    );
    return '$_temp0 on $date will be marked as paid at once.';
  }

  @override
  String get qadhaConfirmCta => 'Yes, paid';

  @override
  String qadhaPaidOneSnackbar(String prayer, String date) {
    return '$prayer on $date paid.';
  }

  @override
  String qadhaPaidAllSnackbar(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count qadha',
      one: '$count qadha',
    );
    return '$_temp0 on $date paid.';
  }

  @override
  String get qadhaNoDebt => 'No prayer debt';

  @override
  String qadhaUnconfirmedDaysRow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days not recorded',
      one: '$count day not recorded',
    );
    return '$_temp0';
  }

  @override
  String qadhaErrorPrefix(String message) {
    return 'Failed to load qadha data: $message';
  }

  @override
  String get qadhaEmptyTitle => 'No records yet';

  @override
  String get qadhaEmptyBody =>
      'Start logging your prayers on Home. Qadha debt is calculated from your first record, and only from prayers you marked as missed.';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get qiblaNoSensor =>
      'Your device doesn\'t have a compass sensor (magnetometer).';

  @override
  String get qiblaLocationDisabled =>
      'Location services are off. Turn on GPS and try again.';

  @override
  String get qiblaPermissionDenied =>
      'Location permission is needed to determine the Qibla direction.';

  @override
  String get qiblaPermissionDeniedForever =>
      'Location permission permanently denied. Enable it from the app\'s Settings.';

  @override
  String get qiblaOpenSettings => 'Open Settings';

  @override
  String get qiblaSensorError =>
      'Failed to read the compass sensor. Try moving the device away from metal objects or magnets, then reopen the page.';

  @override
  String get qiblaWaitingSensor => 'Waiting for compass sensor data...';

  @override
  String get qiblaFacingQibla => 'You\'re facing the Qibla';

  @override
  String get qiblaTurnToArrow => 'Turn the device toward the arrow';

  @override
  String get qiblaCompassSemantics => 'Qibla compass';

  @override
  String qiblaDirectionSemantics(String degrees, String status) {
    return 'Qibla direction $degrees, $status';
  }

  @override
  String get qiblaNotAlignedSemantics =>
      'not yet aligned, turn the device toward the arrow';

  @override
  String get qiblaDirectionLabel => 'Qibla direction';

  @override
  String qiblaCardinalName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'U': 'North',
      'TL': 'Northeast',
      'T': 'East',
      'TG': 'Southeast',
      'S': 'South',
      'BD': 'Southwest',
      'B': 'West',
      'BL': 'Northwest',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String qiblaDialLabel(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'U': 'N',
      'TL': 'NE',
      'T': 'E',
      'TG': 'SE',
      'S': 'S',
      'BD': 'SW',
      'B': 'W',
      'BL': 'NW',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNeverBackedUp => 'Never backed up';

  @override
  String get settingsNoCitySelected => 'No city selected';

  @override
  String get settingsLocationSubtitle => 'Used for daily prayer times';

  @override
  String get settingsNotifTitle => 'Enable Notifications';

  @override
  String get settingsNotifSubtitle => 'Notified when a prayer time begins';

  @override
  String get settingsNotifBlockedBanner =>
      'Notification permission denied by the system — reminders won\'t appear even with this on.';

  @override
  String get settingsRequestPermissionAgain => 'Request Permission Again';

  @override
  String get settingsThemeModeTitle => 'Display Mode';

  @override
  String get settingsThemeLight => 'Light Mode';

  @override
  String get settingsThemeDark => 'Dark Mode';

  @override
  String get settingsThemeDialogTitle => 'Choose Display Mode';

  @override
  String get settingsThemeSystemSubtitle =>
      'Automatically matches your device setting';

  @override
  String get settingsThemeLightSubtitle => 'Bright appearance for daytime';

  @override
  String get settingsThemeDarkSubtitle => 'Dark appearance for nighttime';

  @override
  String get settingsBackupSectionTitle => 'Backup & Data';

  @override
  String get settingsGoogleNotLoggedIn => 'Not signed in to Google';

  @override
  String get settingsGoogleLoginSubtitle => 'For backing up to Google Drive';

  @override
  String get settingsSigningOut => 'Signing out...';

  @override
  String settingsSignOutFailed(String error) {
    return 'Failed to sign out: $error';
  }

  @override
  String get settingsAutoBackupTitle => 'Auto Backup';

  @override
  String get settingsAutoBackupSubtitle => 'Automatic backup to Google Drive';

  @override
  String get settingsBackupDataTitle => 'Backup Data';

  @override
  String settingsBackupDataSubtitle(String date) {
    return 'Last: $date';
  }

  @override
  String get settingsRestoreDataTitle => 'Restore Data';

  @override
  String get settingsRestoreDataSubtitle => 'Restore data from Google Drive';

  @override
  String get settingsConnectingGoogle => 'Connecting to Google...';

  @override
  String get settingsLoginSuccessNoBackup =>
      'Signed in. No backup available to restore yet.';

  @override
  String get settingsLoginSuccessKeptLocal => 'Signed in. Local data kept.';

  @override
  String get settingsRestoringLatest => 'Restoring the latest backup...';

  @override
  String get settingsLoginRestoredSuccess =>
      'Signed in and restored the latest backup!';

  @override
  String settingsSignInFailed(String error) {
    return 'Failed to sign in: $error';
  }

  @override
  String get settingsRestoreOnLoginTitle => 'Restore Backup Data?';

  @override
  String get settingsRestoreOnLoginBody =>
      'Signed in. You already have data on this device. Restoring the latest backup will OVERWRITE it. Continue?';

  @override
  String get settingsKeepLocalData => 'Keep Local Data';

  @override
  String get settingsRestoreCta => 'Restore';

  @override
  String get settingsBackupNowTitle => 'Backup Now?';

  @override
  String get settingsBackupNowBody =>
      'Your data will be saved to Google Drive.';

  @override
  String get settingsBackupCta => 'Backup';

  @override
  String get settingsBackingUp => 'Backing up...';

  @override
  String get settingsBackupSuccess => 'Backup successful!';

  @override
  String settingsBackupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get settingsLoadingBackupList => 'Loading backup list...';

  @override
  String get settingsChooseBackupTitle => 'Choose a Backup to Restore';

  @override
  String get settingsNoBackupsSaved => 'No backups saved yet.';

  @override
  String get settingsUnknownDate => 'Unknown date';

  @override
  String get settingsLatestBadge => 'Latest';

  @override
  String get settingsDeleteBackupTooltip => 'Delete backup';

  @override
  String get settingsDeleteBackupTitle => 'Delete Backup?';

  @override
  String settingsDeleteBackupBody(String date) {
    return 'The backup from $date will be permanently deleted from Google Drive.';
  }

  @override
  String get settingsDeleteCta => 'Delete';

  @override
  String get settingsBackupDeleted => 'Backup deleted.';

  @override
  String settingsDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String settingsListBackupFailed(String error) {
    return 'Failed to fetch backup list: $error';
  }

  @override
  String get settingsRestoreConfirmTitle => 'Restore Data?';

  @override
  String get settingsRestoreConfirmBody =>
      'WARNING: This will OVERWRITE your current data with the backup\'s data. Continue?';

  @override
  String get settingsRestoringData => 'Restoring data...';

  @override
  String get settingsRestoreSuccess => 'Data restored successfully!';

  @override
  String settingsRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get settingsAppVersionTitle => 'App Version';

  @override
  String get settingsResetDataTitle => 'Reset Data';

  @override
  String get settingsResetDataSubtitle =>
      'Erase data on this device (Drive backup stays safe)';

  @override
  String get settingsResetConfirmTitle => 'Reset Data?';

  @override
  String get settingsResetConfirmBody =>
      'This will erase ALL prayer and setting data on this device. Your Google Drive backup will NOT be deleted, so it can still be restored. This action can\'t be undone.';

  @override
  String get settingsResetCta => 'Reset';

  @override
  String get settingsResetting => 'Resetting data...';

  @override
  String get settingsResetSuccess => 'Data reset successfully';

  @override
  String settingsResetFailed(String error) {
    return 'Reset failed: $error';
  }

  @override
  String settingsCityChanged(String city) {
    return 'City changed to $city';
  }

  @override
  String get settingsCitySearchTitle => 'Search City';

  @override
  String settingsCitySearchHint(int count) {
    return 'Enter city name (min. $count letters)';
  }

  @override
  String get settingsCitySearchTooltip => 'Search';

  @override
  String settingsCitySearchMinChars(int count) {
    return 'Type at least $count letters.';
  }

  @override
  String checkinEditTitle(String prayer) {
    return 'Edit $prayer';
  }

  @override
  String checkinRecordTitle(String prayer) {
    return 'Log $prayer';
  }

  @override
  String get checkinDeleteTooltip => 'Delete entry';

  @override
  String get checkinOnTimeTitle => 'On Time';

  @override
  String get checkinOnTimeSubtitle => 'Prayed at the start of its time';

  @override
  String get checkinLateTitle => 'Qadha / Late';

  @override
  String get checkinLateSubtitle => 'Prayed outside its time';

  @override
  String get checkinMissedTitle => 'Missed';

  @override
  String get checkinMissedSubtitle => 'Didn\'t pray';

  @override
  String get prayerCardNotRecorded => 'Not recorded';

  @override
  String prayerCardStatusSemantics(String status) {
    return 'Status: $status';
  }

  @override
  String get unconfirmedDaysPickerTitle =>
      'Choose a date to open it in Calendar';
}
