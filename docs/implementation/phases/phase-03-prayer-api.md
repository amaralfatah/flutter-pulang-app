# Phase 3: Prayer Times API Integration

## Tujuan
Integrasi dengan MyQuran API untuk mendapatkan jadwal solat berdasarkan lokasi.

## Deliverables

### 3.1 Prayer API Service
- Integration dengan MyQuran API (https://api.myquran.com)
- Endpoint pencarian kota: `/v2/sholat/kota/cari/{nama}`
- Endpoint jadwal solat: `/v2/sholat/jadwal/{id}/{tahun}/{bulan}/{tanggal}`
- Error handling untuk offline mode

### 3.2 Caching Strategy
- Cache jadwal solat harian ke tabel `prayer_times`
- Cek cache sebelum fetch API
- Auto-refresh setiap hari baru

### 3.3 City Selection
- List kota dari API search
- Simpan city_id ke SharedPreferences
- Handle case kota tidak ditemukan

## Kriteria Selesai
- [x] API service berfungsi fetch jadwal
- [x] Caching berjalan dengan benar
- [x] Offline mode menggunakan cache
- [x] City search dan selection works

