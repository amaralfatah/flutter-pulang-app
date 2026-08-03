import 'package:flutter_test/flutter_test.dart';
import 'package:pulang/models/models.dart';
import 'package:pulang/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migrasi v2 -> v3: qadha tidak lagi punya penanda sendiri.
///
/// Dulu solat yang sudah diqadha tetap berstatus `missed` dengan `qadha_paid_at`
/// terisi. Kalau migrasi ini meleset, seluruh qadha yang sudah dibayar user akan
/// muncul lagi sebagai hutang — jadi jalurnya diuji langsung di atas SQLite.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  /// Bentuk tabel `prayers` persis seperti pada skema v2.
  Future<Database> openV2Database() async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 2),
    );
    await db.execute('''
      CREATE TABLE prayers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prayer_name TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        time TEXT,
        notes TEXT,
        qadha_paid_at TEXT
      )
    ''');
    return db;
  }

  Future<void> insertV2Row(
    Database db, {
    required PrayerName name,
    required PrayerStatus status,
    String? qadhaPaidAt,
  }) async {
    await db.insert('prayers', {
      'prayer_name': name.value,
      'date': '2026-01-12',
      'status': status.value,
      'qadha_paid_at': qadhaPaidAt,
    });
  }

  Future<String> statusOf(Database db, PrayerName name) async {
    final rows = await db.query(
      'prayers',
      columns: ['status'],
      where: 'prayer_name = ?',
      whereArgs: [name.value],
    );
    return rows.single['status'] as String;
  }

  late Database db;

  setUp(() async => db = await openV2Database());
  tearDown(() async => db.close());

  test('hutang yang sudah dibayar jadi berstatus late', () async {
    await insertV2Row(
      db,
      name: PrayerName.subuh,
      status: PrayerStatus.missed,
      qadhaPaidAt: '2026-01-20T08:00:00.000',
    );

    await DatabaseService.onUpgrade(db, 2, 3);

    expect(await statusOf(db, PrayerName.subuh), 'late');
  });

  test('hutang yang belum dibayar tetap terlewat', () async {
    await insertV2Row(db, name: PrayerName.isya, status: PrayerStatus.missed);

    await DatabaseService.onUpgrade(db, 2, 3);

    expect(await statusOf(db, PrayerName.isya), 'missed');
  });

  test('status lain tidak disentuh', () async {
    await insertV2Row(db, name: PrayerName.dzuhur, status: PrayerStatus.onTime);
    await insertV2Row(db, name: PrayerName.ashar, status: PrayerStatus.late);

    await DatabaseService.onUpgrade(db, 2, 3);

    expect(await statusOf(db, PrayerName.dzuhur), 'on_time');
    expect(await statusOf(db, PrayerName.ashar), 'late');
  });

  test('menjalankan migrasi dua kali tidak mengubah hasilnya', () async {
    await insertV2Row(
      db,
      name: PrayerName.maghrib,
      status: PrayerStatus.missed,
      qadhaPaidAt: '2026-01-20T08:00:00.000',
    );

    await DatabaseService.onUpgrade(db, 2, 3);
    await DatabaseService.onUpgrade(db, 2, 3);

    expect(await statusOf(db, PrayerName.maghrib), 'late');
  });
}
