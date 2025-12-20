import 'package:dio/dio.dart';

import '../models/models.dart';
import 'database_service.dart';
import 'preferences_service.dart';

/// City model for search results
class City {
  final String id;
  final String name;

  City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) =>
      City(id: json['id'] as String, name: json['lokasi'] as String);

  @override
  String toString() => 'City(id: $id, name: $name)';
}

/// Prayer API service for fetching prayer times from MyQuran API
class PrayerApiService {
  final Dio _dio;
  final DatabaseService _databaseService;
  final PreferencesService _preferencesService;

  static const String _baseUrl = 'https://api.myquran.com/v2/sholat';

  PrayerApiService({
    Dio? dio,
    DatabaseService? databaseService,
    PreferencesService? preferencesService,
  }) : _dio = dio ?? Dio(),
       _databaseService = databaseService ?? DatabaseService(),
       _preferencesService = preferencesService ?? PreferencesService();

  // ============ CITY SEARCH ============

  /// Search cities by name
  Future<List<City>> searchCities(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _dio.get('$_baseUrl/kota/cari/$query');

      if (response.statusCode == 200 && response.data['status'] == true) {
        final data = response.data['data'] as List;
        return data.map((json) => City.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      // Handle network errors
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw PrayerApiException('Tidak ada koneksi internet');
      }
      throw PrayerApiException('Gagal mencari kota: ${e.message}');
    } catch (e) {
      throw PrayerApiException('Error: $e');
    }
  }

  /// Get all available cities (cached or from API)
  Future<List<City>> getAllCities() async {
    try {
      final response = await _dio.get('$_baseUrl/kota/semua');

      if (response.statusCode == 200 && response.data['status'] == true) {
        final data = response.data['data'] as List;
        return data.map((json) => City.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw PrayerApiException('Gagal mengambil daftar kota: $e');
    }
  }

  // ============ PRAYER TIMES ============

  /// Get prayer times for a specific date
  /// Uses cache if available, otherwise fetches from API
  Future<PrayerTime?> getPrayerTimes({
    required String cityId,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);

    // Check cache first
    final cached = await _databaseService.getPrayerTimeByDate(dateStr, cityId);
    if (cached != null) {
      return cached;
    }

    // Fetch from API
    try {
      final prayerTime = await _fetchPrayerTimesFromApi(
        cityId: cityId,
        year: date.year,
        month: date.month,
        day: date.day,
      );

      if (prayerTime != null) {
        // Cache the result
        await _databaseService.insertPrayerTime(prayerTime);
        // Clean up old cache
        await _databaseService.deleteOldPrayerTimes();
      }

      return prayerTime;
    } on DioException catch (e) {
      // If offline, return null (caller should handle this)
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return null;
      }
      throw PrayerApiException('Gagal mengambil jadwal solat: ${e.message}');
    }
  }

  /// Fetch prayer times from MyQuran API
  Future<PrayerTime?> _fetchPrayerTimesFromApi({
    required String cityId,
    required int year,
    required int month,
    required int day,
  }) async {
    final url = '$_baseUrl/jadwal/$cityId/$year/$month/$day';

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['status'] == true) {
        return PrayerTime.fromApiResponse(response.data['data'], cityId);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get today's prayer times using saved city
  Future<PrayerTime?> getTodayPrayerTimes() async {
    final cityId = await _preferencesService.getCityId();
    if (cityId == null) return null;

    return getPrayerTimes(cityId: cityId, date: DateTime.now());
  }

  /// Prefetch prayer times for the next few days
  Future<void> prefetchPrayerTimes({
    required String cityId,
    int days = 3,
  }) async {
    final now = DateTime.now();
    for (int i = 0; i <= days; i++) {
      final date = now.add(Duration(days: i));
      await getPrayerTimes(cityId: cityId, date: date);
    }
  }

  // ============ UTILITY ============

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get the next prayer name and time based on current time
  Future<({String name, String time, Duration remaining})?>
  getNextPrayer() async {
    final prayerTime = await getTodayPrayerTimes();
    if (prayerTime == null) return null;

    final now = DateTime.now();
    final prayers = [
      ('Subuh', prayerTime.subuh),
      ('Dzuhur', prayerTime.dzuhur),
      ('Ashar', prayerTime.ashar),
      ('Maghrib', prayerTime.maghrib),
      ('Isya', prayerTime.isya),
    ];

    for (final (name, timeStr) in prayers) {
      final time = _parseTime(timeStr);
      if (time != null && time.isAfter(now)) {
        return (name: name, time: timeStr, remaining: time.difference(now));
      }
    }

    // All prayers passed, next is tomorrow's Subuh
    return null;
  }

  /// Parse time string (HH:mm) to DateTime
  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Custom exception for Prayer API errors
class PrayerApiException implements Exception {
  final String message;

  PrayerApiException(this.message);

  @override
  String toString() => 'PrayerApiException: $message';
}
