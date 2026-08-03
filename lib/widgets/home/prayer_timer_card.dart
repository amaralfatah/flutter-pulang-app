import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../patterns/pattern_painters.dart';

/// Tinggi konten pada state normal: baris label/jam (20) + 4 + baris
/// nama/countdown (32). Dipakai sebagai tinggi *minimum* state loading dan
/// error supaya kartu tidak melompat saat jadwal selesai dimuat — bukan tinggi
/// tetap, karena teks yang diperbesar lewat Dynamic Type harus tetap muat.
const double _minContentHeight = 56;

/// Teks sekunder di atas primaryContainer. 0.85 adalah batas bawah yang masih
/// lolos WCAG AA (4.5:1) di kedua tema — light mode yang menentukan: pada 0.80
/// rasionya turun ke 4.47. Hierarki selebihnya dibentuk oleh ukuran dan bobot
/// huruf, bukan dengan menurunkan opacity lebih jauh.
const double _secondaryAlpha = 0.85;

/// Card widget yang menampilkan info solat berikutnya
/// Dengan background pattern Islamic geometric
class PrayerTimerCard extends ConsumerWidget {
  const PrayerTimerCard({super.key, this.onTap});

  /// Membuka check-in untuk solat berikutnya. Null saat belum ada solat
  /// berikutnya yang bisa dicatat (mis. masih menunggu jadwal dimuat).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimesState = ref.watch(prayerTimesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      // primaryContainer, bukan primary: di dark theme primary adalah hijau
      // menyala yang membuat kartu ini jadi satu-satunya blok terang di layar.
      // Nada container menyamakannya dengan badge 5/5 dan lingkaran centang.
      color: colorScheme.primaryContainer,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: IslamicPatternPainter(
            color: colorScheme.onPrimaryContainer,
            opacity: 0.1,
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildContent(context, prayerTimesState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PrayerTimesState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimaryContainer;

    // Tinggi minimum, bukan tetap: kartu tetap tidak melompat saat jadwal
    // selesai dimuat, tapi teks yang diperbesar masih boleh mendorongnya.
    if (state.isLoading) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minContentHeight),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: onPrimary, strokeWidth: 3),
          ),
        ),
      );
    }

    if (state.error != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minContentHeight),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: onPrimary.withValues(alpha: _secondaryAlpha),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Gagal memuat jadwal',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: onPrimary),
              ),
            ),
          ],
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    // Kapital kecil dibaca huruf-per-huruf oleh sebagian pembaca layar, jadi
    // labelnya diucapkan ulang dalam bentuk normal.
    final label = Semantics(
      label: 'Solat berikutnya',
      child: ExcludeSemantics(
        child: Text(
          'SOLAT BERIKUTNYA',
          style: textTheme.labelSmall?.copyWith(
            color: onPrimary.withValues(alpha: _secondaryAlpha),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    // Pada ukuran teks yang diperbesar, nama solat dan countdown tidak lagi
    // muat berdampingan — dipaksakan pun hasilnya salah satu terpotong. Di
    // atas ambang itu susunannya ditumpuk supaya kartu tumbuh ke bawah, yang
    // memang perilaku yang diharapkan saat pengguna memperbesar teks.
    final stacked = MediaQuery.textScalerOf(context).scale(100) > 135;

    final time = Text(
      state.nextPrayerTime ?? '--:--',
      style: textTheme.bodyMedium?.copyWith(
        color: onPrimary.withValues(alpha: _secondaryAlpha),
        letterSpacing: 0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 4),
          _buildPrayerName(context, state.nextPrayerName),
          const SizedBox(height: 4),
          time,
          const SizedBox(height: 4),
          _buildCountdown(context, state.remainingTime),
        ],
      );
    }

    // Grid 2×2. Dibangun sebagai dua Row bertumpuk, bukan dua Column
    // berdampingan: dengan dua Column, tinggi baris kiri dan kanan berbeda
    // (label 14px vs jam 20px) sehingga tidak ada garis yang benar-benar
    // sejajar. Sebagai Row, tiap baris merapikan dirinya sendiri.
    //
    // Perataannya baseline, bukan end. Kedua sisi tiap baris berbeda ukuran
    // huruf (11 vs 14, lalu 22 vs 24), dan CrossAxisAlignment.end menyamakan
    // dasar kotak baris — yang descent-nya ikut membesar bersama ukuran huruf,
    // sehingga garis dasar hurufnya sendiri malah tidak sejajar.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: label),
            const SizedBox(width: 12),
            time,
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: _buildPrayerName(context, state.nextPrayerName),
            ),
            const SizedBox(width: 12),

            // Sengaja tanpa Flexible. Flexible bawaannya flex 1, sehingga Row
            // membagi ruang bebas setengah-setengah: kolom kiri dipaksa
            // selebar separuh kartu lalu terpotong elipsis, sementara kolom
            // kanan hanya memakai sebagian jatahnya dan menyisakan celah
            // kosong di kanan. Countdown harus selebar isinya saja, sisanya
            // milik kolom kiri.
            _buildCountdown(context, state.remainingTime),
          ],
        ),
      ],
    );
  }

  /// Nama solat, dengan keterangan "(besok)" bila ada.
  ///
  /// Jam solat sengaja tidak ikut ditampilkan di sini: angka itu sudah muncul
  /// pada baris solat yang sama di daftar tepat di bawah kartu. Menggabungnya
  /// ke baris ini membuat teks tidak muat di layar sempit dan berakhir
  /// terpotong jadi elipsis.
  Widget _buildPrayerName(BuildContext context, String? fullName) {
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = Theme.of(context).colorScheme.onPrimaryContainer;

    final name = fullName ?? '-';
    final suffixStart = name.indexOf(' (');

    return Text.rich(
      TextSpan(
        text: suffixStart == -1 ? name : name.substring(0, suffixStart),
        style: textTheme.titleLarge?.copyWith(
          color: onPrimary,
          fontWeight: FontWeight.bold,
        ),
        children: [
          if (suffixStart != -1)
            TextSpan(
              text: name.substring(suffixStart),
              style: textTheme.bodyMedium?.copyWith(
                color: onPrimary.withValues(alpha: _secondaryAlpha),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Sisa waktu sebagai satu angka besar, mis. "6j 05m".
  ///
  /// Tanpa kata "lagi" di bawahnya: satuannya sudah terbaca dari "j" dan "m",
  /// sehingga kata itu hanya menambah baris kedua yang membuat kolom kanan
  /// tidak bisa sejajar dengan kolom kiri. Bentuk panjangnya tetap diucapkan
  /// utuh ke pembaca layar lewat Semantics di bawah.
  Widget _buildCountdown(BuildContext context, Duration? duration) {
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = Theme.of(context).colorScheme.onPrimaryContainer;

    // Hanya terjadi bila jam pada jadwal gagal diurai; kasus "semua solat hari
    // ini sudah lewat" tetap punya hitungan mundur ke Subuh besok.
    if (duration == null) {
      return Text(
        'Waktu tidak\ndiketahui',
        textAlign: TextAlign.end,
        style: textTheme.labelMedium?.copyWith(
          color: onPrimary.withValues(alpha: _secondaryAlpha),
        ),
      );
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    final String value;
    if (hours > 0) {
      value = '${hours}j ${minutes.toString().padLeft(2, '0')}m';
    } else if (minutes > 0) {
      value = '${minutes}m';
    } else {
      value = '<1m';
    }

    return Semantics(
      label: 'Sisa waktu ${_spokenDuration(hours, minutes)}',
      excludeSemantics: true,
      // Angka tabular: nilainya berubah tiap menit, dan dengan lebar digit
      // proporsional tepi blok ini akan bergeser-geser tiap pergantian.
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: textTheme.headlineSmall?.copyWith(
          color: onPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// Bentuk panjang untuk pembaca layar — "6j 05m" tidak terbaca wajar.
  String _spokenDuration(int hours, int minutes) {
    if (hours > 0) return '$hours jam $minutes menit lagi';
    if (minutes > 0) return '$minutes menit lagi';
    return 'sebentar lagi';
  }
}
