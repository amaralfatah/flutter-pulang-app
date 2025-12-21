import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Database service for SQLite operations
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'pulang.db';
  static const int _databaseVersion = 1;

  /// Get database instance (singleton)
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
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
    if (existing != null) {
      return await updatePrayer(prayer.copyWith(id: existing.id));
    } else {
      return await insertPrayer(prayer);
    }
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

  /// Get count of prayers by status for a date range
  Future<Map<String, int>> getStatusCount({
    required String startDate,
    required String endDate,
  }) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT status, COUNT(*) as count
      FROM prayers
      WHERE date >= ? AND date <= ?
      GROUP BY status
    ''',
      [startDate, endDate],
    );

    final counts = <String, int>{'on_time': 0, 'late': 0, 'missed': 0};

    for (final row in result) {
      counts[row['status'] as String] = row['count'] as int;
    }
    return counts;
  }

  /// Get total completed prayers count
  Future<int> getTotalCompletedCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM prayers
      WHERE status IN ('on_time', 'late')
    ''');
    return result.first['count'] as int;
  }

  /// Get current streak (consecutive days with all 5 prayers)
  Future<int> getCurrentStreak() async {
    final db = await database;
    int streak = 0;
    DateTime currentDate = DateTime.now();

    while (true) {
      final dateStr =
          '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM prayers
        WHERE date = ? AND status IN ('on_time', 'late')
      ''',
        [dateStr],
      );

      final count = result.first['count'] as int;

      if (count == 5) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        // If it's today and incomplete (count < 5), ignore and check yesterday.
        // If it's NOT today and incomplete, the streak is broken.
        final now = DateTime.now();
        final isToday =
            currentDate.year == now.year &&
            currentDate.month == now.month &&
            currentDate.day == now.day;

        if (isToday) {
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }
    return streak;
  }

  /// Get weekly statistics (completed prayers per day)
  Future<Map<String, int>> getWeeklyStats() async {
    final db = await database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final startDate =
        '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
    final endDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final result = await db.rawQuery(
      '''
      SELECT date, COUNT(*) as count
      FROM prayers
      WHERE date >= ? AND date <= ? AND status IN ('on_time', 'late')
      GROUP BY date
      ORDER BY date ASC
    ''',
      [startDate, endDate],
    );

    final stats = <String, int>{};
    for (final row in result) {
      stats[row['date'] as String] = row['count'] as int;
    }
    return stats;
  }

  /// Get history stats (date + completion count + prayer statuses)
  Future<List<Map<String, dynamic>>> getHistoryStats({
    int limit = 30,
    int offset = 0,
  }) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT date, 
             COUNT(CASE WHEN status IN ('on_time', 'late') THEN 1 END) as completed_count,
             GROUP_CONCAT(CASE WHEN status IN ('on_time', 'late') THEN prayer_name END) as completed_prayers,
             GROUP_CONCAT(CASE WHEN status = 'on_time' THEN prayer_name END) as on_time_prayers,
             GROUP_CONCAT(CASE WHEN status = 'late' THEN prayer_name END) as late_prayers
      FROM prayers
      GROUP BY date
      ORDER BY date DESC
      LIMIT ? OFFSET ?
    ''',
      [limit, offset],
    );

    return result;
  }

  /// Get monthly prayer summary (completed count per date for calendar view)
  Future<Map<String, int>> getMonthPrayerSummary(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final result = await db.rawQuery(
      '''
      SELECT date, COUNT(CASE WHEN status IN ('on_time', 'late') THEN 1 END) as completed_count
      FROM prayers
      WHERE date >= ? AND date <= ?
      GROUP BY date
    ''',
      [startDate, endDate],
    );

    final summary = <String, int>{};
    for (final row in result) {
      summary[row['date'] as String] = row['completed_count'] as int;
    }
    return summary;
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

  /// Auto-mark prayers as missed for past dates that have no records
  /// This should be called when app starts or when date changes
  Future<void> markMissedPrayers() async {
    final db = await database;
    final now = DateTime.now();

    // Get yesterday's date
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    // Get all prayers for yesterday
    final yesterdayPrayers = await getPrayersByDate(yesterdayStr);

    // Check which prayers are missing for yesterday
    final allPrayerNames = [
      PrayerName.subuh,
      PrayerName.dzuhur,
      PrayerName.ashar,
      PrayerName.maghrib,
      PrayerName.isya,
    ];

    final recordedPrayerNames = yesterdayPrayers
        .map((p) => p.prayerName)
        .toSet();
    final missingPrayerNames = allPrayerNames
        .where((name) => !recordedPrayerNames.contains(name))
        .toList();

    // Insert missed prayers for yesterday
    if (missingPrayerNames.isNotEmpty) {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final prayerName in missingPrayerNames) {
          final missedPrayer = Prayer(
            prayerName: prayerName,
            date: yesterdayStr,
            status: PrayerStatus.missed,
            time: null,
            notes: 'Auto-marked as missed',
          );
          batch.insert(
            'prayers',
            missedPrayer.toMap(),
            conflictAlgorithm:
                ConflictAlgorithm.ignore, // Don't overwrite if exists
          );
        }
        await batch.commit(noResult: true);
      });
    }
  }
}
