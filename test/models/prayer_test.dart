import 'package:flutter_test/flutter_test.dart';
import 'package:pulang/models/models.dart';

/// Mengqadha sebuah solat hanya memindahkan statusnya `missed` -> `late`.
/// Tidak ada status ketiga "terlewat tapi sudah dibayar".
void main() {
  Prayer prayerWith(PrayerStatus status) => Prayer(
    prayerName: PrayerName.subuh,
    date: '2026-01-12',
    status: status,
  );

  test('yang masih terlewat belum terpenuhi — inilah hutangnya', () {
    expect(prayerWith(PrayerStatus.missed).isFulfilled, isFalse);
  });

  test('yang sudah diqadha berstatus late, dan terhitung terpenuhi', () {
    final qadhaed = prayerWith(PrayerStatus.missed)
        .copyWith(status: PrayerStatus.late);

    expect(qadhaed.status, PrayerStatus.late);
    expect(qadhaed.isFulfilled, isTrue);
  });

  test('tepat waktu juga terpenuhi', () {
    expect(prayerWith(PrayerStatus.onTime).isFulfilled, isTrue);
  });

  test('status bolak-balik lewat map penyimpanan tetap utuh', () {
    for (final status in PrayerStatus.values) {
      final restored = Prayer.fromMap(prayerWith(status).toMap());
      expect(restored.status, status);
    }
  });
}
