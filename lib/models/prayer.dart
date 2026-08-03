/// Prayer status enum
enum PrayerStatus {
  /// Prayer completed on time
  onTime,

  /// Prayer completed late (qadha)
  late,

  /// Prayer was missed
  missed,
}

/// Prayer name enum for the 5 daily prayers
enum PrayerName { subuh, dzuhur, ashar, maghrib, isya }

/// Extension to convert PrayerStatus to/from string
extension PrayerStatusExtension on PrayerStatus {
  String get value {
    switch (this) {
      case PrayerStatus.onTime:
        return 'on_time';
      case PrayerStatus.late:
        return 'late';
      case PrayerStatus.missed:
        return 'missed';
    }
  }

  static PrayerStatus fromString(String value) {
    switch (value) {
      case 'on_time':
        return PrayerStatus.onTime;
      case 'late':
        return PrayerStatus.late;
      case 'missed':
        return PrayerStatus.missed;
      default:
        return PrayerStatus.missed;
    }
  }
}

/// Extension to convert PrayerName to/from string
extension PrayerNameExtension on PrayerName {
  String get value => name;

  /// Nama yang ditampilkan ke user.
  String get displayName {
    switch (this) {
      case PrayerName.subuh:
        return 'Subuh';
      case PrayerName.dzuhur:
        return 'Dzuhur';
      case PrayerName.ashar:
        return 'Ashar';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isya:
        return 'Isya';
    }
  }

  static PrayerName fromString(String value) {
    return PrayerName.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PrayerName.subuh,
    );
  }
}

/// Prayer model for tracking daily prayer records
class Prayer {
  final int? id;
  final PrayerName prayerName;
  final String date; // Format: YYYY-MM-DD
  final PrayerStatus status;
  final String? time; // Format: HH:mm
  final String? notes;

  Prayer({
    this.id,
    required this.prayerName,
    required this.date,
    required this.status,
    this.time,
    this.notes,
  });

  /// Sudah dikerjakan, entah tepat waktu atau terlambat. Mengqadha sebuah solat
  /// yang terlewat berarti mengubah statusnya jadi [PrayerStatus.late] — tidak
  /// ada status ketiga untuk "terlewat tapi sudah dibayar".
  bool get isFulfilled => status != PrayerStatus.missed;

  /// Convert to Map for SQLite storage
  Map<String, dynamic> toMap() => {
    'id': id,
    'prayer_name': prayerName.value,
    'date': date,
    'status': status.value,
    'time': time,
    'notes': notes,
  };

  /// Create Prayer from SQLite Map
  factory Prayer.fromMap(Map<String, dynamic> map) => Prayer(
    id: map['id'] as int?,
    prayerName: PrayerNameExtension.fromString(map['prayer_name'] as String),
    date: map['date'] as String,
    status: PrayerStatusExtension.fromString(map['status'] as String),
    time: map['time'] as String?,
    notes: map['notes'] as String?,
  );

  /// Convert to JSON for backup
  Map<String, dynamic> toJson() => toMap();

  /// Create Prayer from JSON backup
  factory Prayer.fromJson(Map<String, dynamic> json) => Prayer.fromMap(json);

  /// Create a copy with modified fields
  Prayer copyWith({
    int? id,
    PrayerName? prayerName,
    String? date,
    PrayerStatus? status,
    String? time,
    String? notes,
  }) {
    return Prayer(
      id: id ?? this.id,
      prayerName: prayerName ?? this.prayerName,
      date: date ?? this.date,
      status: status ?? this.status,
      time: time ?? this.time,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Prayer(id: $id, prayerName: ${prayerName.value}, date: $date, status: ${status.value}, time: $time)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prayer &&
        other.id == id &&
        other.prayerName == prayerName &&
        other.date == date &&
        other.status == status &&
        other.time == time &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(id, prayerName, date, status, time, notes);
}
