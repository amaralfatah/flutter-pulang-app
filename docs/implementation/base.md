# System Analysis - Aplikasi Pulang (Simplified for Personal Use)

## 1. Overview

### 1.1 Informasi Dasar
- **Nama:** Pulang - Presensi Solat
- **Package:** com.pulang.prayer
- **Platform:** Flutter (Android & iOS)
- **Jenis:** Personal App (untuk diri sendiri)
- **Storage:** SQLite + Google Drive Backup

### 1.2 Tujuan Sederhana
Aplikasi untuk mencatat solat harian agar bisa tracking konsistensi sendiri, dengan backup otomatis ke Google Drive supaya data tidak hilang.

---

## 2. Fitur Inti (Keep It Simple!)

### 2.1 Yang HARUS Ada (MVP)

#### ✅ Check-In Solat
- 5 tombol untuk 5 waktu solat
- Tap = tercatat
- Status otomatis: Tepat Waktu / Qadha / Terlewat
- Bisa edit kalau salah input

#### ✅ Waktu Solat Otomatis
- Pilih kota (data Kemenag RI via MyQuran API)
- Ambil jadwal solat harian
- Notifikasi saat masuk waktu

#### ✅ Statistik Sederhana
- Lihat hari ini: sudah solat apa saja
- Lihat minggu ini: berapa persen konsistensi
- Streak counter: berapa hari berturut-turut

#### ✅ Backup ke Google Drive
- Auto backup seminggu sekali
- Bisa backup manual
- Bisa restore kalau ganti HP

### 2.2 Yang BOLEH Ditambah Nanti (Nice to Have)

- 📊 Grafik bulanan
- 🏆 Achievement/badge
- 📝 Catatan per solat
- 🌙 Kalender Hijriyah
- 🌍 Multi bahasa
- 🎨 Dark mode

---

## 3. Arsitektur Sederhana

### 3.1 Layer Aplikasi

```
┌─────────────────────┐
│   UI Screens        │  ← Flutter Widgets
│   (4-5 screens)     │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   Logic Layer       │  ← Riverpod (state management)
│   (Providers)       │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   Services          │  ← Database, Google Drive, Notification
│   (3-4 services)    │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   Data Storage      │  ← SQLite + SharedPreferences
└─────────────────────┘
```

**Penjelasan:**
- **UI**: Yang user lihat (home, stats, settings)
- **Logic**: Atur data dan status aplikasi (dengan Riverpod)
- **Services**: Handle database, backup, notifikasi
- **Storage**: Simpan data

### 3.2 Database (Cukup 2 Tabel!)

**Tabel 1: prayers**
```sql
CREATE TABLE prayers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  prayer_name TEXT NOT NULL,  -- subuh, dzuhur, ashar, maghrib, isya
  date TEXT NOT NULL,         -- format: YYYY-MM-DD
  status TEXT NOT NULL,       -- on_time, late, missed
  time TEXT,                  -- waktu check-in, format: HH:mm
  notes TEXT
);
```
Contoh data:
```
1, "subuh", "2024-01-15", "on_time", "05:30", ""
2, "dzuhur", "2024-01-15", "late", "13:15", "lupa meeting"
```

**Tabel 2: prayer_times** (Cache jadwal solat dari API)
```sql
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
);
```

**Settings → SharedPreferences** (bukan tabel!)
```dart
// Simpan di SharedPreferences, bukan SQLite
// Contoh:
await prefs.setString('city_id', '1301');
await prefs.setString('city_name', 'Jakarta');
await prefs.setString('last_backup', '2024-01-15');
await prefs.setBool('notification_enabled', true);
```

> [!TIP]
> Gunakan **SharedPreferences** untuk settings key-value sederhana.
> SQLite hanya untuk data yang perlu query (prayers, prayer_times).

**Total: 2 tabel SQLite + SharedPreferences** = Simpel & efisien!

---

## 4. Google Drive Backup

### 4.1 Cara Kerja

```
Setiap 7 hari:
1. Export semua data dari SQLite ke JSON
2. Upload file JSON ke Google Drive (folder hidden)
3. Simpan info: "terakhir backup kapan"

Kalau ganti HP:
1. Login Google
2. Download file backup terbaru
3. Import ke SQLite lokal
4. Selesai!
```

### 4.2 Format Backup (JSON Sederhana)

```json
{
  "backup_date": "2024-01-15",
  "prayers": [
    {
      "prayer_name": "subuh",
      "date": "2024-01-15",
      "status": "on_time",
      "time": "05:30"
    }
  ],
  "settings": {
    "location": "Jakarta",
    "notification_enabled": true
  }
}
```

**Benefit:**
- ✅ Gratis (15GB Google Drive)
- ✅ Aman (OAuth Google)
- ✅ Auto-sync
- ✅ Mudah restore

---

## 5. MyQuran API (Waktu Solat)

### 5.1 Kenapa MyQuran API?

| Aspek | MyQuran API | Package `adhan` |
|-------|-------------|-----------------|
| **Sumber Data** | Kemenag RI (resmi) | Perhitungan algoritma |
| **Akurasi** | Standar Indonesia | Perlu setup metode hitung |
| **GPS** | Tidak perlu | Perlu geolocator |
| **API Key** | Tidak perlu | - |
| **Harga** | Gratis | - |

### 5.2 Endpoint API

**Step 1: Cari ID Kota**
```
GET https://api.myquran.com/v2/sholat/kota/cari/{nama_kota}
```

Contoh: `https://api.myquran.com/v2/sholat/kota/cari/jakarta`

Response:
```json
{
  "status": true,
  "data": [
    {"id": "1301", "lokasi": "KOTA JAKARTA"}
  ]
}
```

**Step 2: Ambil Jadwal Solat**
```
GET https://api.myquran.com/v2/sholat/jadwal/{idKota}/{tahun}/{bulan}/{tanggal}
```

Contoh: `https://api.myquran.com/v2/sholat/jadwal/1301/2025/12/20`

Response:
```json
{
  "status": true,
  "data": {
    "id": 1301,
    "lokasi": "KOTA JAKARTA",
    "daerah": "DKI JAKARTA",
    "jadwal": {
      "tanggal": "Sabtu, 20/12/2025",
      "imsak": "04:03",
      "subuh": "04:13",
      "terbit": "05:32",
      "dhuha": "06:02",
      "dzuhur": "11:54",
      "ashar": "15:20",
      "maghrib": "18:08",
      "isya": "19:24",
      "date": "2025-12-20"
    }
  }
}
```

### 5.3 Flow di Aplikasi

```
Pertama Kali Buka:
1. User pilih kota dari dropdown/search
2. Simpan ID kota ke SharedPreferences

Setiap Hari:
1. Cek tanggal hari ini
2. Kalau belum ada cache → fetch dari API
3. Simpan jadwal ke SQLite (cache 1 hari)
4. Tampilkan di UI

Offline Mode:
- Pakai data cache dari SQLite
- Jadwal solat relatif sama setiap hari (beda menit)
```

### 5.4 Caching Strategy

```
Flow caching jadwal solat:
1. Cek apakah ada data hari ini di tabel prayer_times
2. Kalau tidak ada → fetch dari MyQuran API
3. Simpan response ke prayer_times
4. Tampilkan di UI
5. Cache berlaku 1 hari (fetch ulang besoknya)
```

> [!NOTE]
> Tabel `prayer_times` sudah didefinisikan di bagian 3.2 Database.

---

## 6. Fitur Notifikasi

### 6.1 Jenis Notifikasi

1. **Saat Masuk Waktu**
   - "Sudah masuk waktu Dzuhur"
   - User bisa langsung check-in dari notifikasi

2. **Reminder (Optional)**
   - 15 menit sebelum waktu habis
   - "Jangan lupa solat Ashar"

3. **Daily Summary (Optional)**
   - Malam hari: "Hari ini kamu sudah solat 4 dari 5 waktu"

### 6.2 Setting Notifikasi

- ON/OFF per waktu solat
- Pilih suara (Adzan/Bell/Silent)
- Vibrate ON/OFF

### 6.3 Implementasi Teknis

> [!IMPORTANT]
> Untuk notifikasi yang **reliable** di Android (terutama saat app di-kill),
> gunakan `android_alarm_manager_plus` untuk exact alarm scheduling.

```dart
// Flow scheduling notifikasi:
// 1. Setelah fetch jadwal solat dari API
// 2. Schedule alarm untuk setiap waktu solat
// 3. Ketika alarm trigger → tampilkan notifikasi

// Packages yang dibutuhkan:
// - flutter_local_notifications (tampilkan notif)
// - android_alarm_manager_plus (schedule exact alarm)
```

---

## 6. Screens (Minimal 4 Screen)

### Screen 1: Home
```
┌─────────────────────┐
│ 🕌 Pulang           │
│ 📍 Jakarta          │
│                     │
│ Solat Berikutnya:   │
│ ASHAR - 15:30       │
│ ⏱️ 2 jam lagi       │
│                     │
│ Hari Ini: 3/5 ✅    │
│ Streak: 🔥 12 hari  │
│                     │
│ ✓ Subuh    05:30   │
│ ✓ Dzuhur   12:15   │
│ ✓ Ashar    15:30   │
│ ○ Maghrib  18:15   │
│ ○ Isya     19:30   │
│                     │
│ [Tap untuk Check-In]│
└─────────────────────┘
```

### Screen 2: Statistics
```
┌─────────────────────┐
│ 📊 Statistik        │
│                     │
│ Minggu Ini:         │
│ ████████░░ 80%      │
│                     │
│ Bulan Ini:          │
│ [Calendar View]     │
│                     │
│ Total Solat: 487    │
│ Streak Terlama: 25  │
└─────────────────────┘
```

### Screen 3: History
```
┌─────────────────────┐
│ 📖 Riwayat          │
│                     │
│ 15 Jan 2024 ✅ 5/5  │
│ 14 Jan 2024 ⚠️ 4/5  │
│ 13 Jan 2024 ✅ 5/5  │
│ 12 Jan 2024 ✅ 5/5  │
│                     │
│ [Tap untuk detail]  │
└─────────────────────┘
```

### Screen 4: Settings
```
┌─────────────────────┐
│ ⚙️ Pengaturan       │
│                     │
│ Lokasi              │
│ └ 📍 Jakarta        │
│                     │
│ Notifikasi          │
│ └ 🔔 Aktif          │
│                     │
│ Backup              │
│ ├ ☁️ Connected      │
│ ├ Terakhir: 1 Jan   │
│ └ [Backup Sekarang] │
│                     │
│ Tentang Aplikasi    │
└─────────────────────┘
```

---

## 7. Development Plan (Realistis!)

### Phase 1: Core Features (2-3 Minggu)
**Week 1:**
- ✅ Setup project Flutter
- ✅ Buat database SQLite
- ✅ UI dasar (Home screen)
- ✅ Check-in functionality

**Week 2:**
- ✅ Hitung waktu solat (pakai library)
- ✅ Notifikasi lokal
- ✅ Statistics sederhana

**Week 3:**
- ✅ History screen
- ✅ Settings screen
- ✅ Polish UI

### Phase 2: Google Drive (1 Minggu)
**Week 4:**
- ✅ Setup Google Sign-In
- ✅ Backup ke Google Drive
- ✅ Restore dari backup
- ✅ Testing

### Phase 3: Enhancement (Kapan Sempat)
- 📊 Grafik lebih bagus
- 🏆 Achievement system
- 🌙 Hijri calendar
- 🎨 Dark mode
- 🌍 Bahasa Inggris

**Total MVP: 1 Bulan**

---

## 8. Technology Stack (Simplified for Personal App)

> [!NOTE]
> **Semua package TANPA versi** - selalu gunakan versi terbaru saat `flutter pub add`.
> Stack ini sudah **disederhanakan** untuk personal app - tanpa code generation!

### 8.1 Flutter Dependencies (10 Packages Only!)

```yaml
dependencies:
  # State Management
  flutter_riverpod:            # State management (tanpa generator)
  
  # Navigation
  go_router:                   # Declarative routing
  
  # Database & Storage
  sqflite:                     # SQLite database
  path_provider:               # Akses folder device
  shared_preferences:          # Key-value storage untuk settings
  
  # Google Drive Backup
  google_sign_in:              # Google authentication
  googleapis:                  # Google APIs (Drive)
  
  # Prayer Times API
  dio:                         # HTTP client untuk MyQuran API
  
  # Notification
  flutter_local_notifications: # Local push notification
  android_alarm_manager_plus:  # Exact alarm scheduling (reliable!)
  
  # UI & Formatting
  intl:                        # Format tanggal/waktu

# Tidak perlu dev_dependencies untuk code generation!
```

### 8.2 Kenapa TANPA Code Generation?

**Untuk Personal App:**
| Dengan Code Gen | Tanpa Code Gen |
|-----------------|----------------|
| +5 packages (freezed, build_runner, dll) | 10 packages total |
| Harus run `build_runner` setiap edit model | Langsung edit & hot reload |
| Learning curve lebih tinggi | Straightforward |
| Bagus untuk tim besar | Cukup untuk 1 developer |

> [!TIP]
> Untuk personal app, **simplicity > scalability**.
> Kalau nanti butuh, bisa tambahkan code generation kemudian.

### 8.3 Command untuk Install

```bash
# Install semua dependencies sekaligus
flutter pub add flutter_riverpod go_router
flutter pub add sqflite path_provider shared_preferences
flutter pub add google_sign_in googleapis
flutter pub add dio
flutter pub add flutter_local_notifications android_alarm_manager_plus
flutter pub add intl
```

### 8.4 Model Classes (Manual, Simpel)

```dart
// Contoh Prayer model tanpa freezed
class Prayer {
  final int? id;
  final String prayerName;
  final String date;
  final String status;
  final String? time;
  final String? notes;

  Prayer({
    this.id,
    required this.prayerName,
    required this.date,
    required this.status,
    this.time,
    this.notes,
  });

  // Untuk SQLite
  Map<String, dynamic> toMap() => {
    'id': id,
    'prayer_name': prayerName,
    'date': date,
    'status': status,
    'time': time,
    'notes': notes,
  };

  factory Prayer.fromMap(Map<String, dynamic> map) => Prayer(
    id: map['id'],
    prayerName: map['prayer_name'],
    date: map['date'],
    status: map['status'],
    time: map['time'],
    notes: map['notes'],
  );

  // Untuk JSON backup  
  Map<String, dynamic> toJson() => toMap();
  factory Prayer.fromJson(Map<String, dynamic> json) => Prayer.fromMap(json);
}
```

**Total: 10 packages** - Minimal, efisien, mudah di-maintain!

---

## 9. Folder Structure (Recommended)

```
lib/
├── main.dart                    # Entry point
├── app/
│   ├── app.dart                 # MaterialApp wrapper
│   └── router.dart              # GoRouter configuration
│
├── models/                      # Data classes
│   ├── prayer.dart
│   └── prayer_time.dart
│
├── services/                    # Business logic
│   ├── database_service.dart    # SQLite operations
│   ├── prayer_api_service.dart  # MyQuran API calls
│   ├── backup_service.dart      # Google Drive backup
│   └── notification_service.dart
│
├── providers/                   # Riverpod providers
│   ├── prayer_provider.dart
│   ├── settings_provider.dart
│   └── statistics_provider.dart
│
└── screens/                     # UI screens
    ├── home/
    │   └── home_screen.dart
    ├── statistics/
    │   └── statistics_screen.dart
    ├── history/
    │   └── history_screen.dart
    └── settings/
        └── settings_screen.dart
```

> [!TIP]
> Struktur ini **flat dan simpel** - cocok untuk personal app.
> Tidak pakai feature-first architecture yang lebih kompleks.

---

## 10. Yang TIDAK Perlu (Untuk Pribadi)

❌ **User Authentication System**
   - Tidak perlu login/register
   - Langsung pakai, data lokal aja

❌ **Backend Server**
   - Tidak perlu server sendiri
   - Google Drive sudah cukup

❌ **Multi-user Support**
   - Cuma untuk diri sendiri
   - Tidak perlu role/permission

❌ **Complex Analytics**
   - Statistik sederhana sudah cukup
   - Tidak perlu machine learning

❌ **Social Features**
   - Tidak perlu share/compare dengan orang lain
   - Privacy first!

❌ **Payment/Subscription**
   - Gratis, tidak ada monetisasi
   - Tidak perlu payment gateway

❌ **Complex Testing**
   - Manual testing aja cukup
   - Unit test untuk fungsi penting aja

❌ **CI/CD Pipeline**
   - Build manual aja
   - Deploy ke device sendiri

❌ **Code Generation (freezed, riverpod_generator)**
   - Overhead untuk personal app
   - Manual model classes sudah cukup

---

## 11. Estimasi Effort

### Untuk Developer dengan Experience Flutter:

**MVP (Fitur Inti):**
- Full-time: 1-2 minggu
- Part-time (2 jam/hari): 1 bulan

**Dengan Google Drive:**
- Tambah 3-5 hari

**Polish & Testing:**
- Tambah 1 minggu

**Total Realistis: 1-2 Bulan** (part-time)

### Breakdown Per Fitur:

| Fitur | Estimasi | Prioritas |
|-------|----------|-----------|
| Setup Project | 2 jam | P0 |
| Database SQLite | 4 jam | P0 |
| UI Screens | 8 jam | P0 |
| Check-in Logic | 4 jam | P0 |
| Prayer Times | 6 jam | P0 |
| Notifications | 6 jam | P0 |
| Statistics | 4 jam | P0 |
| Google Sign-In | 4 jam | P1 |
| Backup/Restore | 8 jam | P1 |
| Polish & Bug Fix | 8 jam | P1 |
| **TOTAL** | **~54 jam** | |

**Artinya:** Kalau coding 2 jam per hari = selesai dalam 1 bulan

---

## 12. Kesimpulan

### ✅ Yang Perlu Fokus:
1. **Keep it simple** - Fitur inti dulu
2. **Works offline** - Data lokal prioritas
3. **Backup cloud** - Biar aman kalau ganti HP
4. **Easy to use** - Max 3 tap untuk check-in

### 🎯 Success Metrics (Personal):
- ✅ Bisa check-in dalam 5 detik
- ✅ Notifikasi tepat waktu
- ✅ Data tidak hilang
- ✅ Bisa tracking konsistensi
- ✅ Membantu meningkatkan ibadah

### 💡 Tips Development:
1. Mulai dari fitur paling sederhana dulu
2. Test di HP sendiri setiap hari
3. Perbaiki yang mengganggu kamu sebagai user
4. Fitur tambahan boleh nanti-nanti
5. Yang penting: **IT WORKS!**

---

## 13. Skenario Distribusi

### 12.1 Untuk Pribadi (Default)
```
Kamu Build → Install di HP sendiri → Pakai sendiri
```
- ✅ Paling sederhana
- ✅ 100% gratis
- ✅ Tidak perlu publish

### 12.2 Share dengan Teman/Keluarga

**Opsi A: Share APK File (Android)** ⭐ RECOMMENDED
```
Build APK → Share via WhatsApp/Email → Teman Install
```

### 12.3 Arsitektur Multi-User

**Important:** Aplikasi ini **single-user per device**, bukan multi-tenant!

```
┌─────────────────────────────────────────┐
│         DEVICE A (Kamu)                 │
│  ┌───────────┐       ┌──────────────┐  │
│  │  SQLite   │       │ Google Drive │  │
│  │  Local A  │ ←──→  │   Account A  │  │
│  └───────────┘       └──────────────┘  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│         DEVICE B (Teman)                │
│  ┌───────────┐       ┌──────────────┐  │
│  │  SQLite   │       │ Google Drive │  │
│  │  Local B  │ ←──→  │   Account B  │  │
│  └───────────┘       └──────────────┘  │
└─────────────────────────────────────────┘

❌ TIDAK ADA koneksi antar device
✅ PRIVACY 100% terjaga
✅ Data TIDAK shared
```

**Benefit:**
- Tidak perlu backend server
- Tidak perlu user management
- Tidak ada biaya hosting
- Privacy maksimal
- Simple architecture

### 12.4 Distribusi APK (Step-by-Step)

**Build APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Share ke Teman:**
1. File APK ada di folder output
2. Share via WhatsApp/Telegram/Google Drive/Email
3. File size: ~20-50 MB (tergantung dependencies)

**Teman Install:**
1. Download APK
2. Buka file APK
3. Android minta izin "Install Unknown Apps"
4. Enable izin
5. Install
6. Done!

**Update Aplikasi:**
1. Build APK versi baru
2. Share lagi ke teman
3. Install (akan replace yang lama)
4. Data tetap aman (tidak hilang)

### 12.5 Considerations

**Kalau Ingin Share ke Banyak Orang:**

**Pertimbangan Teknis:**
- Google Drive API quota: Unlimited (untuk free tier)
- Setiap user pakai Google Drive sendiri
- Tidak ada beban di server kamu (karena tidak ada server!)

**Pertimbangan Legal:**
- Kalau publish ke store, baca terms & conditions
- Privacy policy mungkin diperlukan
- Data user disimpan di device mereka sendiri (good!)

**Pertimbangan Support:**
- Siap bantu teman kalau ada bug?
- Update rutin atau one-time aja?
- Feedback channel (WhatsApp group?)

**Saran:**
- Untuk <10 orang: **Share APK** (simple & gratis)
- Untuk 10-100 orang: **TestFlight** (iOS) atau **Play Store Beta** (Android)
- Untuk >100 orang: **Publish ke Store** (lebih profesional)

---

## 14. Next Steps

### Langkah Awal:
1. ✅ Setup Flutter project
2. ✅ Design database schema (2 tabel)
3. ✅ Buat UI mockup sederhana (di kertas juga boleh)
4. ✅ Code fitur check-in dulu
5. ✅ Test, iterate, improve
6. ✅ Build APK & test di device sendiri
7. ✅ (Optional) Share ke teman untuk beta testing

### Resources Yang Dibutuhkan:
- Flutter SDK
- Android Studio / VS Code
- Google Cloud Console account (untuk Drive API)
- Smartphone untuk testing
- **Kemauan & Konsistensi** 💪

> [!CAUTION]
> **Security Reminder:**
> File `client_secret_*.json` JANGAN di-commit ke Git!
> Tambahkan ke `.gitignore`:
> ```
> client_secret*.json
> ```

### Estimasi Biaya:

**Untuk Personal Use:**
- **Rp 0,-** (100% gratis!)
  - Flutter: Gratis
  - Google Drive API: Gratis
  - Google Drive Storage: 15GB gratis per user
  - Hosting: Tidak perlu
  - Database: SQLite (lokal, gratis)

**Untuk Share ke Teman (APK):**
- **Rp 0,-** (100% gratis!)

**Untuk Publish ke Store:**
- Google Play: **$25** (one-time) = ~Rp 390.000
- Apple App Store: **$99/tahun** = ~Rp 1.550.000/tahun

---

**Intinya:** 

Aplikasi ini **bisa dipakai banyak orang** tanpa perlu backend server atau biaya hosting! Setiap user:
- Install di device sendiri
- Data tersimpan lokal
- Backup ke Google Drive sendiri
- Privacy terjaga 100%

**Recommended path:**
1. Build untuk diri sendiri dulu
2. Kalau jadi & bagus, share APK ke teman dekat (5-10 orang)
3. Kalau banyak yang minta, baru consider publish ke Play Store

Mulai dari sederhana, tambah fitur kalau perlu. Done is better than perfect! 🚀