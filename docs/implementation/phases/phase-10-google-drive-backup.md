# Phase 10: Google Drive Backup & Restore

## Tujuan
Implementasi backup data ke Google Drive untuk data safety.

## Deliverables

### 10.1 Google Sign-In
- Setup google_sign_in package
- Request Drive API scope
- Handle sign-in/sign-out flow
- Save auth state

### 10.2 Backup Service
- Export semua data prayers ke JSON
- Include settings dalam backup
- Upload ke Google Drive (app-specific folder)
- Simpan last backup timestamp

### 10.3 Restore Service
- List available backups dari Drive
- Download backup file
- Parse JSON dan import ke SQLite
- Handle merge/replace conflict

### 10.4 Auto-Backup (Opsional)
- Schedule backup mingguan
- Background backup
- Notification saat backup selesai

### 10.5 UI Integration
- Backup status di Settings screen
- Manual backup button
- Restore button dengan konfirmasi
- Progress indicator saat backup/restore

## Kriteria Selesai
- [x] Google Sign-In berfungsi
- [x] Manual backup works
- [x] Restore works dan data muncul
- [x] Last backup timestamp updated
- [x] Error handling untuk network issues
