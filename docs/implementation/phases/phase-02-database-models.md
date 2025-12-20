# Phase 2: Database & Models

## Tujuan
Implementasi database SQLite dan model classes untuk menyimpan data solat.

## Deliverables

### 2.1 Model Classes
- **Prayer Model**: id, prayer_name, date, status, time, notes
- **PrayerTime Model**: id, city_id, date, subuh, dzuhur, ashar, maghrib, isya
- Implementasi toMap(), fromMap(), toJson(), fromJson()

### 2.2 Database Service
- Inisialisasi SQLite database
- Buat tabel `prayers` dan `prayer_times`
- CRUD operations untuk Prayer
- Query untuk statistics (count by status, streak, dll)

### 2.3 SharedPreferences Helper
- Helper class untuk settings (city_id, city_name, notification_enabled, dll)
- Get/Set methods untuk setiap setting

## Kriteria Selesai
- [x] Model classes lengkap dengan serialization
- [x] Database service dengan semua CRUD operations
- [x] SharedPreferences helper berfungsi
- [ ] Unit test untuk database operations (opsional)

