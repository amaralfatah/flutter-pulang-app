import 'prayer.dart';

/// Rekap satu waktu solat sepanjang riwayat pencatatan.
class PrayerTally {
  final int onTime;
  final int late;

  /// Terlewat dan belum diqadha — ini yang jadi hutang.
  final int outstanding;

  /// Terlewat tapi sudah diqadha.
  final int qadhaPaid;

  /// Slot hari lampau yang tidak punya catatan sama sekali. Bukan hutang:
  /// aplikasi tidak tahu apakah solatnya dikerjakan atau tidak.
  final int unrecorded;

  const PrayerTally({
    this.onTime = 0,
    this.late = 0,
    this.outstanding = 0,
    this.qadhaPaid = 0,
    this.unrecorded = 0,
  });

  /// Sudah dikerjakan — tepat waktu, terlambat, atau lunas lewat qadha.
  int get fulfilled => onTime + late + qadhaPaid;

  /// Slot yang statusnya sudah pasti (bukan "belum tercatat").
  int get known => fulfilled + outstanding;

  int get total => known + unrecorded;

  /// Porsi terpenuhi dari slot yang statusnya diketahui. Slot "belum tercatat"
  /// sengaja tidak masuk penyebut supaya angkanya tidak menuduh hari-hari yang
  /// user memang tidak sempat membuka aplikasi.
  double get fulfilledRatio => known == 0 ? 0 : fulfilled / known;

  PrayerTally operator +(PrayerTally other) => PrayerTally(
    onTime: onTime + other.onTime,
    late: late + other.late,
    outstanding: outstanding + other.outstanding,
    qadhaPaid: qadhaPaid + other.qadhaPaid,
    unrecorded: unrecorded + other.unrecorded,
  );
}

/// Buku besar seluruh riwayat solat, dihitung sejak catatan pertama.
///
/// Dua rentang sengaja dibedakan:
/// - **Slot lampau** (catatan pertama s/d kemarin) jadi dasar `unrecorded` dan
///   persentase, karena hari ini masih berjalan dan belum adil dinilai.
/// - **Hutang qadha** dihitung dari seluruh catatan termasuk hari ini, karena
///   solat yang ditandai terlewat pagi ini sudah jadi hutang saat itu juga.
class PrayerLedger {
  /// Tanggal catatan pertama (YYYY-MM-DD), null kalau belum ada data sama sekali.
  final String? startDate;

  /// Jumlah hari lampau yang tercakup (catatan pertama s/d kemarin).
  final int closedDays;

  final Map<PrayerName, PrayerTally> perPrayer;

  const PrayerLedger({
    required this.startDate,
    required this.closedDays,
    required this.perPrayer,
  });

  static const empty = PrayerLedger(
    startDate: null,
    closedDays: 0,
    perPrayer: {},
  );

  bool get hasData => startDate != null;

  /// Rekap gabungan kelima waktu solat.
  PrayerTally get overall => perPrayer.values.fold(
    const PrayerTally(),
    (sum, tally) => sum + tally,
  );

  /// Total hutang qadha yang belum dibayar.
  int get outstandingQadha => overall.outstanding;

  /// Waktu solat dengan hutang terbanyak — bahan untuk insight.
  /// Null kalau tidak ada hutang sama sekali.
  PrayerName? get weakestPrayer {
    PrayerName? worst;
    var worstCount = 0;
    for (final entry in perPrayer.entries) {
      if (entry.value.outstanding > worstCount) {
        worst = entry.key;
        worstCount = entry.value.outstanding;
      }
    }
    return worst;
  }

  PrayerTally tallyFor(PrayerName name) =>
      perPrayer[name] ?? const PrayerTally();
}
