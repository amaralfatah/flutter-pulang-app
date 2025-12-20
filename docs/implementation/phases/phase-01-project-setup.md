# Phase 1: Project Setup & Foundation

## Tujuan
Setup project Flutter dasar dengan struktur folder dan dependencies yang sudah ditentukan.

## Deliverables

### 1.1 Inisialisasi Project
- Buat project Flutter baru dengan package name `com.amar.pulang` (DONE)
- Setup minimal SDK version untuk Android & iOS
- Konfigurasi app name dan icons

### 1.2 Install Dependencies
- flutter_riverpod (state management)
- go_router (navigation)
- sqflite & path_provider (database)
- shared_preferences (settings storage)
- dio (HTTP client)
- intl (formatting)
- google_sign_in & googleapis (backup)
- flutter_local_notifications & android_alarm_manager_plus (notifikasi)

### 1.3 Struktur Folder
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── router.dart
├── models/
├── services/
├── providers/
└── screens/
```

### 1.4 Konfigurasi Dasar
- Setup MaterialApp dengan theme
- Konfigurasi GoRouter basic
- Setup Riverpod ProviderScope

## Kriteria Selesai
- [ ] Project bisa di-run tanpa error
- [ ] Semua dependencies terinstall
- [ ] Struktur folder sesuai spesifikasi
- [ ] Basic routing berfungsi
