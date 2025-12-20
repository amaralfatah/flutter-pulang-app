/// PrayerTime model for caching prayer schedule from API
class PrayerTime {
  final int? id;
  final String cityId;
  final String date; // Format: YYYY-MM-DD
  final String subuh; // Format: HH:mm
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;
  final String? createdAt;

  PrayerTime({
    this.id,
    required this.cityId,
    required this.date,
    required this.subuh,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
    this.createdAt,
  });

  /// Convert to Map for SQLite storage
  Map<String, dynamic> toMap() => {
    'id': id,
    'city_id': cityId,
    'date': date,
    'subuh': subuh,
    'dzuhur': dzuhur,
    'ashar': ashar,
    'maghrib': maghrib,
    'isya': isya,
    'created_at': createdAt ?? DateTime.now().toIso8601String(),
  };

  /// Create PrayerTime from SQLite Map
  factory PrayerTime.fromMap(Map<String, dynamic> map) => PrayerTime(
    id: map['id'] as int?,
    cityId: map['city_id'] as String,
    date: map['date'] as String,
    subuh: map['subuh'] as String,
    dzuhur: map['dzuhur'] as String,
    ashar: map['ashar'] as String,
    maghrib: map['maghrib'] as String,
    isya: map['isya'] as String,
    createdAt: map['created_at'] as String?,
  );

  /// Convert to JSON for backup
  Map<String, dynamic> toJson() => toMap();

  /// Create PrayerTime from JSON backup
  factory PrayerTime.fromJson(Map<String, dynamic> json) =>
      PrayerTime.fromMap(json);

  /// Create PrayerTime from MyQuran API response
  factory PrayerTime.fromApiResponse(Map<String, dynamic> data, String cityId) {
    final jadwal = data['jadwal'] as Map<String, dynamic>;
    return PrayerTime(
      cityId: cityId,
      date: jadwal['date'] as String,
      subuh: jadwal['subuh'] as String,
      dzuhur: jadwal['dzuhur'] as String,
      ashar: jadwal['ashar'] as String,
      maghrib: jadwal['maghrib'] as String,
      isya: jadwal['isya'] as String,
    );
  }

  /// Get prayer time by prayer name
  String getTimeByName(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        return subuh;
      case 'dzuhur':
        return dzuhur;
      case 'ashar':
        return ashar;
      case 'maghrib':
        return maghrib;
      case 'isya':
        return isya;
      default:
        return '';
    }
  }

  @override
  String toString() {
    return 'PrayerTime(date: $date, cityId: $cityId, subuh: $subuh, dzuhur: $dzuhur, ashar: $ashar, maghrib: $maghrib, isya: $isya)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrayerTime &&
        other.id == id &&
        other.cityId == cityId &&
        other.date == date &&
        other.subuh == subuh &&
        other.dzuhur == dzuhur &&
        other.ashar == ashar &&
        other.maghrib == maghrib &&
        other.isya == isya;
  }

  @override
  int get hashCode =>
      Object.hash(id, cityId, date, subuh, dzuhur, ashar, maghrib, isya);
}
