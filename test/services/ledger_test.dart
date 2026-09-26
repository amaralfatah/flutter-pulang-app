import 'package:flutter_test/flutter_test.dart';
import 'package:pulang/models/models.dart';
import 'package:pulang/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Perhitungan buku besar qadha diuji langsung di atas SQLite in-memory.
/// Angka hutang solat tidak boleh meleset, dan aturannya halus: slot kosong
/// bukan hutang, qadha yang lunas tetap tercatat pernah terlewat, dan hari ini
/// tidak boleh dinilai karena waktunya belum habis.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseService service;

  String at(int daysAgo) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> record(String date, PrayerName name, PrayerStatus status) async {
    await db.insert('prayers', {
      'prayer_name': name.value,
      'date': date,
      'status': status.value,
    });
  }

  /// Isi kelima waktu pada satu hari dengan status yang sama.
  Future<void> recordFullDay(String date, PrayerStatus status) async {
    for (final name in PrayerName.values) {
      await record(date, name, status);
    }
  }

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseService.databaseVersion,
        onCreate: DatabaseService.onCreate,
        onUpgrade: DatabaseService.onUpgrade,
      ),
    );
    service = DatabaseService(database: db);
  });

  tearDown(() async => db.close());

  group('getLedger', () {
    test('tanpa catatan sama sekali menghasilkan ledger kosong', () async {
      final ledger = await service.getLedger();

      expect(ledger.hasData, isFalse);
      expect(ledger.startDate, isNull);
      expect(ledger.outstandingQadha, 0);
    });

    test('mulai dihitung dari tanggal catatan pertama', () async {
      await record(at(9), PrayerName.subuh, PrayerStatus.onTime);
      await record(at(3), PrayerName.isya, PrayerStatus.onTime);

      final ledger = await service.getLedger();

      expect(ledger.startDate, at(9));
      // Hari pertama s/d kemarin, inklusif.
      expect(ledger.closedDays, 9);
    });

    test('slot yang tidak pernah dicatat bukan hutang', () async {
      // Satu catatan saja tiga hari lalu; sisanya kosong melompong.
      await record(at(3), PrayerName.subuh, PrayerStatus.onTime);

      final ledger = await service.getLedger();

      expect(ledger.outstandingQadha, 0, reason: 'kosong bukan berarti bolong');
      expect(ledger.overall.unrecorded, greaterThan(0));
    });

    test('hanya penandaan terlewat yang jadi hutang', () async {
      await record(at(2), PrayerName.subuh, PrayerStatus.missed);
      await record(at(2), PrayerName.dzuhur, PrayerStatus.onTime);

      final ledger = await service.getLedger();

      expect(ledger.outstandingQadha, 1);
      expect(ledger.tallyFor(PrayerName.subuh).outstanding, 1);
      expect(ledger.tallyFor(PrayerName.dzuhur).outstanding, 0);
    });

    test('qadha yang sudah dibayar berhenti jadi hutang', () async {
      await record(at(2), PrayerName.ashar, PrayerStatus.missed);
      await service.payQadhaFor(at(2), PrayerName.ashar);

      final ledger = await service.getLedger();
      final tally = ledger.tallyFor(PrayerName.ashar);

      expect(tally.outstanding, 0);
      expect(tally.late, 1, reason: 'qadha pindah ke status terlambat');
      expect(tally.fulfilled, 1);
    });

    test(
      'solat hari ini yang ditandai terlewat langsung jadi hutang',
      () async {
        await record(at(5), PrayerName.subuh, PrayerStatus.onTime);
        await record(at(0), PrayerName.subuh, PrayerStatus.missed);

        final ledger = await service.getLedger();

        expect(ledger.outstandingQadha, 1);
      },
    );

    test('hari ini tidak dihitung sebagai belum tercatat', () async {
      // Satu-satunya hari dengan catatan adalah kemarin, dan lengkap.
      await recordFullDay(at(1), PrayerStatus.onTime);

      final ledger = await service.getLedger();

      expect(ledger.closedDays, 1);
      expect(ledger.overall.unrecorded, 0, reason: 'hari ini masih berjalan');
      expect(ledger.overall.onTime, 5);
    });

    test('persentase mengabaikan slot yang belum tercatat', () async {
      await record(at(2), PrayerName.subuh, PrayerStatus.onTime);
      await record(at(2), PrayerName.dzuhur, PrayerStatus.missed);
      // 8 slot lain pada rentang ini dibiarkan kosong.

      final overall = (await service.getLedger()).overall;

      expect(overall.known, 2);
      expect(overall.fulfilledRatio, 0.5);
    });
  });

  group('qadha per tanggal', () {
    test('melunasi tepat pada tanggal dan waktu yang dipilih', () async {
      await record(at(30), PrayerName.subuh, PrayerStatus.missed);
      await record(at(30), PrayerName.isya, PrayerStatus.missed);
      await record(at(4), PrayerName.subuh, PrayerStatus.missed);

      final paid = await service.payQadhaFor(at(30), PrayerName.isya);

      expect(paid?.date, at(30));
      expect(paid?.prayerName, PrayerName.isya);
      final isya = await service.getPrayerByDateAndName(
        at(30),
        PrayerName.isya,
      );
      expect(isya?.status, PrayerStatus.late);
      // Subuh yang lebih tua TIDAK ikut terbayar — sasarannya eksplisit.
      final debts = (await service.getOutstandingByDate()).expand(
        (d) => d.prayers,
      );
      expect(debts.map((p) => (p.date, p.prayerName)), [
        (at(30), PrayerName.subuh),
        (at(4), PrayerName.subuh),
      ]);
    });

    test('mengembalikan baris sebelum diubah sebagai bekal urungkan', () async {
      await record(at(5), PrayerName.ashar, PrayerStatus.missed);

      final before = await service.payQadhaFor(at(5), PrayerName.ashar);

      expect(before?.status, PrayerStatus.missed);
      expect(before?.id, isNotNull);
    });

    test('menolak tanggal yang tidak punya hutang', () async {
      await record(at(3), PrayerName.ashar, PrayerStatus.onTime);
      await record(at(4), PrayerName.ashar, PrayerStatus.late);

      expect(await service.payQadhaFor(at(3), PrayerName.ashar), isNull);
      expect(await service.payQadhaFor(at(4), PrayerName.ashar), isNull);
      expect(await service.payQadhaFor(at(9), PrayerName.ashar), isNull);
    });

    test('markMissedAgain mengembalikan qadha jadi hutang', () async {
      await record(at(4), PrayerName.subuh, PrayerStatus.missed);
      final before = await service.payQadhaFor(at(4), PrayerName.subuh);
      expect((await service.getLedger()).outstandingQadha, 0);

      await service.markMissedAgain(before!.id!);

      expect((await service.getLedger()).outstandingQadha, 1);
    });

    test(
      'getOutstandingByDate mengelompokkan dan mengurutkan hutang',
      () async {
        // Skenario tersebar: dua waktu di hari yang sama, lalu hari-hari lain.
        await record(at(40), PrayerName.isya, PrayerStatus.missed);
        await record(at(40), PrayerName.subuh, PrayerStatus.missed);
        await record(at(39), PrayerName.dzuhur, PrayerStatus.missed);
        await record(at(10), PrayerName.subuh, PrayerStatus.missed);
        // Yang sudah diqadha (berstatus late) tidak boleh ikut muncul.
        await record(at(20), PrayerName.maghrib, PrayerStatus.late);

        final days = await service.getOutstandingByDate();

        expect(days.map((d) => d.date), [at(40), at(39), at(10)]);
        expect(days.first.prayers.map((p) => p.prayerName), [
          PrayerName.subuh,
          PrayerName.isya,
        ], reason: 'urut sesuai waktu solat dalam sehari');
      },
    );

    test('hari yang lunas seluruhnya hilang dari daftar', () async {
      await record(at(6), PrayerName.maghrib, PrayerStatus.missed);
      await service.payQadhaFor(at(6), PrayerName.maghrib);

      expect(await service.getOutstandingByDate(), isEmpty);
    });
  });

  group('upsertPrayer', () {
    test('memperbarui baris yang ada, bukan menggandakannya', () async {
      await record(at(8), PrayerName.subuh, PrayerStatus.missed);

      await service.upsertPrayer(
        Prayer(
          prayerName: PrayerName.subuh,
          date: at(8),
          status: PrayerStatus.onTime,
        ),
      );

      final prayers = await service.getPrayersByDate(at(8));
      expect(prayers.length, 1);
      expect(prayers.single.status, PrayerStatus.onTime);
    });
  });

  group('konfirmasi hari kosong', () {
    test('getIncompleteDates melewati hari yang sudah lengkap', () async {
      await recordFullDay(at(3), PrayerStatus.onTime);
      await record(at(2), PrayerName.subuh, PrayerStatus.onTime);

      final incomplete = await service.getIncompleteDates();
      final dates = incomplete.map((d) => d.date);

      expect(dates, isNot(contains(at(3))));
      expect(dates, contains(at(2)));
      expect(dates, contains(at(1)));
    });

    test('fillUnrecordedDay hanya mengisi slot yang kosong', () async {
      await record(at(2), PrayerName.subuh, PrayerStatus.onTime);

      await service.fillUnrecordedDay(at(2), PrayerStatus.missed);

      final prayers = await service.getPrayersByDate(at(2));
      expect(prayers.length, 5);
      expect(
        prayers.firstWhere((p) => p.prayerName == PrayerName.subuh).status,
        PrayerStatus.onTime,
        reason: 'catatan yang sudah ada tidak boleh ditimpa',
      );
      expect((await service.getLedger()).outstandingQadha, 4);
    });

    test(
      'pembatalan konfirmasi hanya menghapus baris yang baru dibuat',
      () async {
        await record(at(2), PrayerName.subuh, PrayerStatus.onTime);

        final ids = await service.fillUnrecordedDay(at(2), PrayerStatus.missed);
        await service.deletePrayersByIds(ids);

        final prayers = await service.getPrayersByDate(at(2));
        expect(prayers.length, 1, reason: 'kembali ke keadaan semula');
        expect(prayers.single.prayerName, PrayerName.subuh);
        expect(prayers.single.status, PrayerStatus.onTime);
      },
    );
  });

  group('streak', () {
    test('hari ini yang belum lengkap tidak memutus rentetan', () async {
      await recordFullDay(at(2), PrayerStatus.onTime);
      await recordFullDay(at(1), PrayerStatus.onTime);
      await record(at(0), PrayerName.subuh, PrayerStatus.onTime);

      expect(await service.getCurrentStreak(), 2);
    });

    test('qadha yang lunas ikut melengkapi hari', () async {
      for (final name in PrayerName.values.take(4)) {
        await record(at(1), name, PrayerStatus.onTime);
      }
      await record(at(1), PrayerName.isya, PrayerStatus.missed);
      await service.payQadhaFor(at(1), PrayerName.isya);

      expect(await service.getCurrentStreak(), 1);
    });

    test('rentetan terpanjang diambil dari seluruh riwayat', () async {
      for (final daysAgo in [10, 9, 8]) {
        await recordFullDay(at(daysAgo), PrayerStatus.onTime);
      }
      await recordFullDay(at(2), PrayerStatus.onTime);

      expect(await service.getLongestStreak(), 3);
      expect(await service.getCurrentStreak(), 0);
    });
  });

  group('migrasi v1 -> v2', () {
    test('membuang tuduhan otomatis tapi menyimpan penandaan user', () async {
      // sqflite ffi berbagi satu database `:memory:`, jadi yang dibuat setUp
      // harus dibuang dulu agar skema v1 di bawah benar-benar dibuat dari nol.
      await db.close();
      await databaseFactory.deleteDatabase(inMemoryDatabasePath);

      // Skema v1: belum ada kolom qadha_paid_at.
      final legacy = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) => db.execute('''
            CREATE TABLE prayers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              prayer_name TEXT NOT NULL,
              date TEXT NOT NULL,
              status TEXT NOT NULL,
              time TEXT,
              notes TEXT
            )
          '''),
        ),
      );

      await legacy.insert('prayers', {
        'prayer_name': 'subuh',
        'date': '2026-01-01',
        'status': 'missed',
        'notes': 'Auto-marked as missed',
      });
      await legacy.insert('prayers', {
        'prayer_name': 'dzuhur',
        'date': '2026-01-01',
        'status': 'missed',
        'notes': null,
      });

      await DatabaseService.onUpgrade(legacy, 1, 2);

      final rows = await legacy.query('prayers');
      expect(rows.length, 1, reason: 'baris otomatis dibuang');
      expect(rows.single['prayer_name'], 'dzuhur');
      expect(rows.single.containsKey('qadha_paid_at'), isTrue);

      // Serahkan ke tearDown supaya penutupannya tetap satu jalur.
      db = legacy;
    });
  });

  group('migrasi v2 -> v3', () {
    test('qadha yang sudah lunas pindah ke status terlambat', () async {
      await db.close();
      await databaseFactory.deleteDatabase(inMemoryDatabasePath);

      // Skema v2: pelunasan qadha masih dicatat lewat qadha_paid_at.
      final legacy = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) => db.execute('''
            CREATE TABLE prayers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              prayer_name TEXT NOT NULL,
              date TEXT NOT NULL,
              status TEXT NOT NULL,
              time TEXT,
              notes TEXT,
              qadha_paid_at TEXT
            )
          '''),
        ),
      );

      await legacy.insert('prayers', {
        'prayer_name': 'subuh',
        'date': '2026-01-01',
        'status': 'missed',
        'qadha_paid_at': '2026-01-02',
      });
      await legacy.insert('prayers', {
        'prayer_name': 'dzuhur',
        'date': '2026-01-01',
        'status': 'missed',
      });

      await DatabaseService.onUpgrade(legacy, 2, 3);

      final rows = await legacy.query('prayers', orderBy: 'id');
      expect(rows.map((r) => r['status']), ['late', 'missed']);

      db = legacy;
    });
  });
}
