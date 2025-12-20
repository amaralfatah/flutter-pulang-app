---
trigger: always_on
---

FLUTTER UI RULES – PULANG APP
FOCUS: UI ONLY (Material 3, Calm, Minimalist)

TUJUAN
Membuat UI Flutter yang konsisten, native Material 3, tenang, dan efisien tanpa custom styling berlebihan.

PRINSIP UTAMA UI

Jangan membuat custom Container dengan BoxDecoration, shadow, atau border manual

Selalu manfaatkan widget Material bawaan

Tampilan dikontrol dari ThemeData, bukan dari widget satu per satu

UI harus sederhana, cepat dirender, dan mudah dibaca

COLOR SYSTEM

Semua warna diambil dari Theme.of(context).colorScheme

Tidak boleh hardcode hex color di widget UI

Primary action: colorScheme.primary

Card surface: colorScheme.surface atau surfaceContainer

Text sekunder / subtitle: colorScheme.onSurfaceVariant

TYPOGRAPHY

Gunakan Plus Jakarta Sans

Selalu gunakan textTheme dari Theme

Judul halaman: textTheme.headlineMedium

Judul item / ListTile: textTheme.titleMedium

Teks biasa: textTheme.bodyMedium

Jangan set fontSize manual kecuali sangat diperlukan

COMPONENT RULES

Cards

Wajib menggunakan Card widget

Tidak membuat container palsu menyerupai Card

Jangan set elevation manual di widget

Bentuk, border, dan warna mengikuti Theme

Buttons

Primary action: FilledButton

Secondary action: OutlinedButton

Tidak menggunakan ElevatedButton lama

Tidak custom padding / radius di widget kecuali ada alasan UX kuat

List

Gunakan ListView.builder

Struktur standar: Card → ListTile

Jangan membangun Row/Column custom jika ListTile sudah cukup

Input

Gunakan TextField / TextFormField

Border menggunakan OutlineInputBorder

Radius mengikuti Theme

Tidak custom border color di widget

Dialog

Gunakan AlertDialog standar

Tidak membuat dialog custom dengan Container

Aksi dialog menggunakan FilledButton / TextButton

LAYOUT & SPACING

Gunakan Padding, SizedBox, dan Spacer standar

Hindari nested Padding berlebihan

Layout harus bersih, satu arah, dan mudah dipindai mata

Jika layout terasa rumit, kemungkinan over-engineered

ANIMATION

Tidak menggunakan animasi

Fokus ke UI statis dan responsif

Performa dan kejelasan lebih penting dari efek visual

VISUAL TONE

Calm

Soft rounded

Flat modern (low elevation)

Tidak ramai

Tidak decorative berlebihan

ATURAN EMAS
Jika sebuah UI bisa dibuat dengan:
Card
ListTile
FilledButton
Text
Padding

Maka gunakan itu. Jangan buat versi custom-nya.