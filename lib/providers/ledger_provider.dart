import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'calendar_provider.dart';
import 'prayer_provider.dart';

/// Satu hari lampau yang catatannya belum lengkap.
typedef IncompleteDay = ({String date, int recorded});

/// Satu tanggal beserta hutang qadha yang masih menempel padanya.
typedef QadhaDay = ({String date, List<Prayer> prayers});

/// Seluruh angka riwayat solat: buku besar all-time, rentetan, dan daftar hari
/// yang masih perlu dikonfirmasi. Layar Riwayat dan Qadha sama-sama membacanya.
class LedgerState {
  final PrayerLedger ledger;
  final int currentStreak;
  final int longestStreak;
  final List<IncompleteDay> incompleteDays;

  /// Hutang yang masih terbuka, dikelompokkan per tanggal dan urut dari yang
  /// paling lama — daftar kerja utama layar Qadha.
  final List<QadhaDay> outstandingByDate;

  /// Qadha yang terakhir dilunasi — jejak yang bisa ditelusuri dan dibatalkan
  /// kapan saja, tidak bergantung pada snackbar yang keburu hilang.
  final List<Prayer> recentlyPaid;

  final bool isLoading;
  final String? error;

  const LedgerState({
    this.ledger = PrayerLedger.empty,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.incompleteDays = const [],
    this.outstandingByDate = const [],
    this.recentlyPaid = const [],
    this.isLoading = false,
    this.error,
  });

  LedgerState copyWith({
    PrayerLedger? ledger,
    int? currentStreak,
    int? longestStreak,
    List<IncompleteDay>? incompleteDays,
    List<QadhaDay>? outstandingByDate,
    List<Prayer>? recentlyPaid,
    bool? isLoading,
    String? error,
  }) {
    return LedgerState(
      ledger: ledger ?? this.ledger,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      incompleteDays: incompleteDays ?? this.incompleteDays,
      outstandingByDate: outstandingByDate ?? this.outstandingByDate,
      recentlyPaid: recentlyPaid ?? this.recentlyPaid,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasData => ledger.hasData;
}

class LedgerNotifier extends Notifier<LedgerState> {
  DatabaseService get _db => ref.read(databaseServiceProvider);

  @override
  LedgerState build() {
    _load();
    return const LedgerState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final ledger = await _db.getLedger();
      final currentStreak = await _db.getCurrentStreak();
      final longestStreak = await _db.getLongestStreak();
      final incompleteDays = await _db.getIncompleteDates();
      final outstandingByDate = await _db.getOutstandingByDate();
      final recentlyPaid = await _db.getRecentlyPaidQadha();

      state = LedgerState(
        ledger: ledger,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        incompleteDays: incompleteDays,
        outstandingByDate: outstandingByDate,
        recentlyPaid: recentlyPaid,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  /// Intip hutang mana saja yang antre dibayar, tanpa mengubah apa pun. Dipakai
  /// untuk memperlihatkan tanggal-tanggalnya sebelum user menekan konfirmasi.
  Future<List<Prayer>> peekOutstandingQadha(PrayerName name, {int limit = 100}) =>
      _db.getOutstandingQadha(name, limit: limit);

  /// Lunasi [count] hutang qadha tertua untuk waktu solat tertentu sekaligus.
  /// Mengembalikan baris yang dilunasi supaya pemanggil bisa menyebut
  /// tanggalnya, atau kosong kalau ternyata sudah tidak ada hutang.
  Future<List<Prayer>> payQadha(PrayerName name, {int count = 1}) async {
    try {
      final paid = await _db.payQadha(name, count: count);
      if (paid.isNotEmpty) await _refreshDependents();
      return paid;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return const [];
    }
  }

  /// Lunasi hutang pada tanggal dan waktu solat tertentu — sasarannya dipilih
  /// langsung, bukan "yang tertua". Ini jalur untuk daftar kerja per tanggal.
  Future<Prayer?> payQadhaFor(String date, PrayerName name) async {
    try {
      final paid = await _db.payQadhaFor(date, name);
      if (paid != null) await _refreshDependents();
      return paid;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Kembalikan sekumpulan pelunasan jadi hutang lagi. Menerima daftar supaya
  /// pembayaran borongan bisa dibatalkan utuh, bukan satu per satu.
  Future<void> undoPayQadha(List<int> prayerIds) async {
    try {
      var changed = false;
      for (final id in prayerIds) {
        if (await _db.undoPayQadhaById(id)) changed = true;
      }
      if (changed) await _refreshDependents();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Konfirmasi sebuah hari yang belum lengkap: sisa slotnya diisi [status].
  /// Inilah cara hari "belum tercatat" berubah jadi data yang pasti — entah
  /// jadi hutang, entah jadi solat yang memang dikerjakan.
  ///
  /// Mengembalikan id baris yang dibuat supaya aksinya bisa dibatalkan utuh.
  Future<List<int>> confirmDay(String date, PrayerStatus status) async {
    try {
      final ids = await _db.fillUnrecordedDay(date, status);
      await _refreshDependents();
      return ids;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return const [];
    }
  }

  /// Batalkan konfirmasi satu hari: baris yang tadi dibuat dihapus lagi.
  Future<void> undoConfirmDay(List<int> ids) async {
    try {
      await _db.deletePrayersByIds(ids);
      await _refreshDependents();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _refreshDependents() async {
    await _load();
    // Kalender disegarkan lewat notifier, bukan di-invalidate, supaya bulan
    // yang sedang ditelusuri user tidak melompat balik ke hari ini.
    await ref.read(calendarProvider.notifier).refresh();
    ref.invalidate(todayPrayersProvider);
  }
}

/// Provider buku besar riwayat solat.
final ledgerProvider = NotifierProvider<LedgerNotifier, LedgerState>(
  LedgerNotifier.new,
);

/// Rentetan hari sempurna yang sedang berjalan.
final currentStreakProvider = Provider<int>(
  (ref) => ref.watch(ledgerProvider).currentStreak,
);

/// Total hutang qadha yang belum dibayar — dipakai juga sebagai badge navigasi.
final outstandingQadhaProvider = Provider<int>(
  (ref) => ref.watch(ledgerProvider).ledger.outstandingQadha,
);
