import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Database service for SQLite operations
class DatabaseService {
  /// [database] hanya diisi oleh test, supaya perhitungan buku besar bisa
  /// diuji di atas SQLite in-memory tanpa menyentuh berkas milik user.
  DatabaseService({Database? database}) : _injected = database;

  final Database? _injected;

  static Database? _database;
  static const String _databaseName = 'pulang.db';
  static const int databaseVersion = 3;

  /// Penanda yang dipakai versi lama saat menandai solat terlewat secara
  /// otomatis. Baris seperti ini bukan keterangan user, jadi migrasi v2
  /// membuangnya — lihat [onUpgrade].
  static const String _legacyAutoMissedNote = 'Auto-marked as missed';

  /// Get database instance (singleton)
  Future<Database> get database async {
    final injected = _injected;
    if (injected != null) return injected;
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }

  /// v1 -> v2: dukung pelunasan qadha, dan buang tuduhan otomatis.
  ///
  /// Versi lama menandai setiap slot kosong kemarin sebagai `missed` tanpa
  /// konfirmasi user. Baris itu tidak membedakan "saya memang tidak solat" dari
  /// "saya lupa buka aplikasi", jadi kalau dibiarkan ia akan muncul sebagai
  /// hutang qadha palsu. Karena isinya murni turunan (tidak ada input user di
  /// dalamnya), baris tersebut dihapus dan harinya kembali berstatus belum
  /// tercatat — user bisa mengonfirmasi sendiri lewat layar Qadha.
  @visibleForTesting
  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE prayers ADD COLUMN qadha_paid_at TEXT');
      await db.delete(
        'prayers',
        where: 'status = ? AND notes = ?',
        whereArgs: [PrayerStatus.missed.value, _legacyAutoMissedNote],
      );
    }

    // v2 -> v3: qadha tidak lagi punya status sendiri.
    //
    // Dulu solat yang diqadha tetap berstatus `missed` dengan penanda terpisah
    // `qadha_paid_at` — dua konsep untuk satu hal yang sama, dan user harus
    // paham bedanya. Sekarang mengqadha cukup memindahkan statusnya ke `late`,
    // sama seperti solat yang memang dikerjakan di luar waktu.
    //
    // Kolomnya sendiri dibiarkan menganggur: SQLite baru bisa DROP COLUMN sejak
    // 3.35, dan versi bawaan perangkat lama belum tentu setinggi itu. Kolom
    // tak terpakai tidak berbiaya — membangun ulang tabel demi membuangnya
    // justru berisiko kehilangan data.
    if (oldVersion < 3) {
      await db.update(
        'prayers',
        {'status': PrayerStatus.late.value},
        where: 'status = ? AND qadha_paid_at IS NOT NULL',
        whereArgs: [PrayerStatus.missed.value],
      );
    }
  }

  /// Create database tables
  @visibleForTesting
  static Future<void> onCreate(Database db, int version) async {
    // Create prayers table
    await db.execute('''
      CREATE TABLE prayers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prayer_name TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        time TEXT,
        notes TEXT
      )
    ''');

    // Create prayer_times table (cache for API data)
    await db.execute('''
      CREATE TABLE prayer_times (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city_id TEXT NOT NULL,
        date TEXT NOT NULL,
        subuh TEXT,
        dzuhur TEXT,
        ashar TEXT,
        maghrib TEXT,
        isya TEXT,
        created_at TEXT
      )
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_prayers_date ON prayers(date)');
    await db.execute(
      'CREATE INDEX idx_prayer_times_date ON prayer_times(date, city_id)',
    );
  }

  // ============ PRAYER CRUD OPERATIONS ============

  /// Insert a new prayer record
  Future<int> insertPrayer(Prayer prayer) async {
    final db = await database;
    return await db.insert('prayers', prayer.toMap());
  }

  /// Update an existing prayer record
  Future<int> updatePrayer(Prayer prayer) async {
    final db = await database;
    return await db.update(
      'prayers',
      prayer.toMap(),
      where: 'id = ?',
      whereArgs: [prayer.id],
    );
  }

  /// Delete a prayer record
  Future<int> deletePrayer(int id) async {
    final db = await database;
    return await db.delete('prayers', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all prayers for a specific date
  Future<List<Prayer>> getPrayersByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'prayers',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.map((map) => Prayer.fromMap(map)).toList();
  }

  /// Get a specific prayer by date and prayer name
  Future<Prayer?> getPrayerByDateAndName(String date, PrayerName name) async {
    final db = await database;
    final maps = await db.query(
      'prayers',
      where: 'date = ? AND prayer_name = ?',
      whereArgs: [date, name.value],
    );
    if (maps.isEmpty) return null;
    return Prayer.fromMap(maps.first);
  }

  /// Insert or update prayer (upsert)
  Future<int> upsertPrayer(Prayer prayer) async {
    final existing = await getPrayerByDateAndName(
      prayer.date,
      prayer.prayerName,
    );
    if (existing == null) return await insertPrayer(prayer);

    return await updatePrayer(prayer.copyWith(id: existing.id));
  }

  /// Qadha sebuah solat yang terlewat: statusnya pindah dari `missed` ke
  /// `late`. Mengembalikan baris sebelum diubah — bekal untuk membatalkannya —
  /// atau null kalau di tanggal itu memang tidak ada hutang.
  Future<Prayer?> payQadhaFor(String date, PrayerName name) async {
    final existing = await getPrayerByDateAndName(date, name);
    if (existing == null || existing.status != PrayerStatus.missed) return null;

    await updatePrayer(existing.copyWith(status: PrayerStatus.late));
    return existing;
  }

  /// Kembalikan sebuah qadha jadi hutang lagi — kebalikan [payQadhaFor].
  Future<void> markMissedAgain(int id) async {
    final db = await database;
    await db.update(
      'prayers',
      {'status': PrayerStatus.missed.value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hutang qadha yang belum dibayar, dikelompokkan per tanggal dan urut dari
  /// yang paling lama. Inilah daftar kerja layar Qadha: hanya hari yang memang
  /// berhutang, tanpa perlu menyisir kalender berbulan-bulan.
  Future<List<({String date, List<Prayer> prayers})>> getOutstandingByDate({
    int limit = 60,
  }) async {
    final db = await database;
    final maps = await db.query(
      'prayers',
      where: 'status = ?',
      whereArgs: [PrayerStatus.missed.value],
      orderBy: 'date ASC',
    );

    final grouped = <String, List<Prayer>>{};
    for (final map in maps) {
      final prayer = Prayer.fromMap(map);
      grouped.putIfAbsent(prayer.date, () => []).add(prayer);
    }

    return grouped.entries
        .take(limit)
        .map(
          (e) => (
            date: e.key,
            // Urutkan sesuai urutan waktu solat dalam sehari, bukan urutan sisip.
            prayers: e.value
              ..sort(
                (a, b) => a.prayerName.index.compareTo(b.prayerName.index),
              ),
          ),
        )
        .toList();
  }

  /// Get all prayers (for backup)
  Future<List<Prayer>> getAllPrayers() async {
    final db = await database;
    final maps = await db.query('prayers', orderBy: 'date DESC, id ASC');
    return maps.map((map) => Prayer.fromMap(map)).toList();
  }

  // ============ PRAYER TIME OPERATIONS ============

  /// Insert prayer time (cache from API)
  Future<int> insertPrayerTime(PrayerTime prayerTime) async {
    final db = await database;
    return await db.insert('prayer_times', prayerTime.toMap());
  }

  /// Get prayer time by date and city
  Future<PrayerTime?> getPrayerTimeByDate(String date, String cityId) async {
    final db = await database;
    final maps = await db.query(
      'prayer_times',
      where: 'date = ? AND city_id = ?',
      whereArgs: [date, cityId],
    );
    if (maps.isEmpty) return null;
    return PrayerTime.fromMap(maps.first);
  }

  /// Delete old prayer times (cleanup cache older than 7 days)
  Future<int> deleteOldPrayerTimes() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final dateStr =
        '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}';
    return await db.delete(
      'prayer_times',
      where: 'date < ?',
      whereArgs: [dateStr],
    );
  }

  // ============ STATISTICS QUERIES ============

  /// Hari-hari yang kelima waktunya sudah terpenuhi, urut menaik. Solat yang
  /// diqadha berstatus `late`, jadi ia ikut terhitung di sini.
  Future<List<DateTime>> _getCompleteDays() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT date, COUNT(*) as count
      FROM prayers
      WHERE status IN ('on_time', 'late')
      GROUP BY date
      HAVING count >= 5
      ORDER BY date ASC
    ''');
    return rows.map((row) => DateTime.parse(row['date'] as String)).toList();
  }

  /// Rentetan hari sempurna yang masih berjalan.
  ///
  /// Hari ini tidak memutus rentetan meski belum lengkap, karena waktunya belum
  /// habis; hitungannya dimulai dari kemarin.
  Future<int> getCurrentStreak() async {
    final days = (await _getCompleteDays()).map(_formatDate).toSet();
    if (days.isEmpty) return 0;

    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(_formatDate(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (days.contains(_formatDate(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Rentetan hari sempurna terpanjang sepanjang riwayat.
  Future<int> getLongestStreak() async {
    final days = await _getCompleteDays();
    if (days.isEmpty) return 0;

    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    return longest;
  }

  /// Get all prayers for a month (for calendar view with individual prayer status)
  Future<List<Prayer>> getMonthPrayers(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final maps = await db.query(
      'prayers',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );

    return maps.map((map) => Prayer.fromMap(map)).toList();
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete all data (for testing or reset)
  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('prayers');
    await db.delete('prayer_times');
  }

  /// Import prayers (bulk insert)
  Future<void> importPrayers(List<Prayer> prayers) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final prayer in prayers) {
        batch.insert(
          'prayers',
          prayer.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // ============ ALL-TIME LEDGER ============

  /// Tanggal catatan paling awal, null kalau belum ada data.
  Future<String?> getFirstRecordDate() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MIN(date) as first_date FROM prayers',
    );
    return result.first['first_date'] as String?;
  }

  /// Susun buku besar seluruh riwayat, sejak catatan pertama sampai kemarin.
  ///
  /// Slot hari lampau yang tidak punya baris dihitung sebagai "belum tercatat",
  /// bukan terlewat. Aplikasi tidak pernah menyimpulkan sendiri bahwa sebuah
  /// solat ditinggalkan — itu hanya berasal dari penandaan user.
  Future<PrayerLedger> getLedger() async {
    final firstDate = await getFirstRecordDate();
    if (firstDate == null) return PrayerLedger.empty;

    final db = await database;
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // Hutang dihitung tanpa batas atas: solat yang ditandai terlewat pagi ini
    // sudah jadi hutang saat itu juga, tidak perlu menunggu hari berganti.
    final statusRows = await db.rawQuery(
      '''
      SELECT prayer_name, status, COUNT(*) as count
      FROM prayers
      GROUP BY prayer_name, status
    ''',
    );

    // "Belum tercatat" hanya bisa dihitung untuk hari yang sudah tutup buku,
    // jadi barisnya dibatasi sampai kemarin.
    final recordedRows = await db.rawQuery(
      '''
      SELECT prayer_name, COUNT(*) as count
      FROM prayers
      WHERE date <= ?
      GROUP BY prayer_name
    ''',
      [yesterday],
    );

    final closedDays = _daysBetween(firstDate, yesterday);
    final recordedPerPrayer = <PrayerName, int>{};
    for (final row in recordedRows) {
      recordedPerPrayer[PrayerNameExtension.fromString(
        row['prayer_name'] as String,
      )] = row['count'] as int;
    }

    final perPrayer = <PrayerName, PrayerTally>{};
    for (final name in PrayerName.values) {
      var onTime = 0, late = 0, outstanding = 0;

      for (final row in statusRows) {
        if (PrayerNameExtension.fromString(row['prayer_name'] as String) !=
            name) {
          continue;
        }
        final count = row['count'] as int;
        final status = PrayerStatusExtension.fromString(
          row['status'] as String,
        );

        switch (status) {
          case PrayerStatus.onTime:
            onTime += count;
          case PrayerStatus.late:
            late += count;
          case PrayerStatus.missed:
            outstanding += count;
        }
      }

      // Tidak boleh negatif: baris hari ini ikut terhitung di statusRows tapi
      // tidak di recordedPerPrayer, jadi selisihnya dijaga di nol.
      final unrecorded =
          (closedDays - (recordedPerPrayer[name] ?? 0)).clamp(0, closedDays);

      perPrayer[name] = PrayerTally(
        onTime: onTime,
        late: late,
        outstanding: outstanding,
        unrecorded: unrecorded,
      );
    }

    return PrayerLedger(
      startDate: firstDate,
      closedDays: closedDays,
      perPrayer: perPrayer,
    );
  }

  /// Hari lampau yang catatannya belum lengkap (kurang dari 5 waktu), terbaru
  /// dulu. Ini bahan untuk mengajak user mengonfirmasi hari yang terlewatkan.
  Future<List<({String date, int recorded})>> getIncompleteDates({
    int limit = 60,
  }) async {
    final firstDate = await getFirstRecordDate();
    if (firstDate == null) return const [];

    final db = await database;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = _formatDate(yesterday);

    final rows = await db.rawQuery(
      '''
      SELECT date, COUNT(*) as count
      FROM prayers
      WHERE date <= ?
      GROUP BY date
    ''',
      [yesterdayStr],
    );

    final countByDate = {
      for (final row in rows) row['date'] as String: row['count'] as int,
    };

    final result = <({String date, int recorded})>[];
    var cursor = yesterday;
    final start = DateTime.parse(firstDate);

    while (!cursor.isBefore(start) && result.length < limit) {
      final dateStr = _formatDate(cursor);
      final recorded = countByDate[dateStr] ?? 0;
      if (recorded < 5) result.add((date: dateStr, recorded: recorded));
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return result;
  }

  /// Isi seluruh slot kosong pada satu hari dengan status yang dipilih user.
  /// Baris yang sudah ada tidak disentuh.
  ///
  /// Mengembalikan id baris yang baru dibuat, supaya pembatalan bisa menghapus
  /// tepat yang ini saja dan tidak ikut membuang catatan lama pada hari yang
  /// sama.
  Future<List<int>> fillUnrecordedDay(String date, PrayerStatus status) async {
    final db = await database;
    final existing = await getPrayersByDate(date);
    final recorded = existing.map((p) => p.prayerName).toSet();
    final missing = PrayerName.values.where((n) => !recorded.contains(n));
    if (missing.isEmpty) return const [];

    final ids = <int>[];
    await db.transaction((txn) async {
      for (final name in missing) {
        final id = await txn.insert(
          'prayers',
          Prayer(prayerName: name, date: date, status: status).toMap(),
        );
        ids.add(id);
      }
    });
    return ids;
  }

  /// Hapus sekumpulan baris sekaligus — pembatalan dari [fillUnrecordedDay].
  Future<void> deletePrayersByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete('prayers', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  /// Format tanggal jadi YYYY-MM-DD.
  static String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Jumlah hari dari [from] sampai [to], inklusif. Nol kalau [to] mendahului
  /// [from] — terjadi saat user baru mencatat hari ini.
  static int _daysBetween(String from, String to) {
    final start = DateTime.parse(from);
    final end = DateTime.parse(to);
    if (end.isBefore(start)) return 0;
    return end.difference(start).inDays + 1;
  }
}
