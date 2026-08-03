import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulang/app/theme/app_colors.dart';
import 'package:pulang/app/theme/app_theme.dart';
import 'package:pulang/providers/prayer_times_provider.dart';
import 'package:pulang/widgets/home/prayer_timer_card.dart';

/// Stub supaya yang diukur adalah baris hero, bukan state loading — tanpa ini
/// provider asli menahan kartu di CircularProgressIndicator dan tesnya lulus
/// tanpa pernah menyentuh tata letak yang sebenarnya diuji.
class _StubNotifier extends PrayerTimesNotifier {
  _StubNotifier(this._state);
  final PrayerTimesState _state;

  @override
  PrayerTimesState build() => _state;
}

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrastRatio(Color foreground, Color background) {
  final a = _luminance(foreground);
  final b = _luminance(background);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

/// Posisi garis dasar huruf (bukan dasar kotak baris) dalam koordinat layar.
///
/// getDistanceToBaseline biasanya hanya boleh dipanggil oleh induk sebuah
/// RenderBox selama layout; di luar itu ia memicu assert. debugCheckingIntrinsics
/// adalah jalan resmi untuk mengukurnya dari luar, dan dikembalikan ke semula
/// lewat try/finally agar tidak membocorkan state ke tes berikutnya.
double _baselineY(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  final wasChecking = RenderObject.debugCheckingIntrinsics;
  RenderObject.debugCheckingIntrinsics = true;
  try {
    final distance = box.getDistanceToBaseline(TextBaseline.alphabetic);
    expect(distance, isNotNull, reason: 'widget harus punya garis dasar teks');
    return box.localToGlobal(Offset(0, distance!)).dy;
  } finally {
    RenderObject.debugCheckingIntrinsics = wasChecking;
  }
}

Color _composite(Color foreground, Color opaqueBackground) {
  final a = foreground.a;
  return Color.from(
    alpha: 1,
    red: foreground.r * a + opaqueBackground.r * (1 - a),
    green: foreground.g * a + opaqueBackground.g * (1 - a),
    blue: foreground.b * a + opaqueBackground.b * (1 - a),
  );
}

void main() {
  // Harus sama dengan _secondaryAlpha di prayer_timer_card.dart.
  const secondaryAlpha = 0.85;

  group('kontras teks sekunder', () {
    // Skema dibangun langsung dari seed, bukan lewat AppTheme: AppTheme
    // memanggil google_fonts yang butuh jaringan, dan di sini hanya warnanya
    // yang relevan.
    for (final brightness in Brightness.values) {
      test('lolos WCAG AA di tema ${brightness.name}', () {
        final scheme = ColorScheme.fromSeed(
          seedColor: AppColors.seedColor,
          brightness: brightness,
        );
        final faded = _composite(
          scheme.onPrimaryContainer.withValues(alpha: secondaryAlpha),
          scheme.primaryContainer,
        );

        // Light mode adalah yang menentukan di sini: pada alpha 0.80 rasionya
        // turun ke 4.47 dan gagal. Tes ini menahan agar nilainya tidak
        // diturunkan lagi "supaya terlihat lebih kalem".
        expect(
          _contrastRatio(faded, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  group('tata letak', () {
    // Nama solat terpanjang digabung countdown terlebar = kasus terburuk.
    const worstCase = PrayerTimesState(
      nextPrayerName: 'Maghrib (besok)',
      nextPrayerTime: '17:58',
      remainingTime: Duration(hours: 23, minutes: 59),
    );

    testWidgets('countdown rapat ke tepi kanan, tanpa celah', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prayerTimesProvider.overrideWith(() => _StubNotifier(worstCase)),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: PrayerTimerCard()),
          ),
        ),
      );
      await tester.pump();

      // Regresi nyata: countdown pernah dibungkus Flexible, yang flex-nya 1,
      // sehingga Row membagi lebar 50/50 — countdown hanya memakai sebagian
      // jatahnya dan menyisakan celah kosong di kanan kartu.
      //
      // Kotak Card sudah termasuk margin-nya sendiri, jadi jarak yang benar
      // dari tepi kotak itu ke teks adalah margin + padding, bukan padding
      // saja.
      const cardMargin = 16.0;
      const horizontalPadding = 20.0;
      final cardRight = tester.getRect(find.byType(Card)).right;
      final countdownRight = tester.getRect(find.text('23j 59m')).right;
      expect(
        cardRight - countdownRight,
        closeTo(cardMargin + horizontalPadding, 1),
        reason: 'countdown harus menempel ke padding kanan, tanpa celah',
      );

      // Jam solat berikutnya harus tampil, dan rata kanan pada garis yang sama
      // dengan countdown — kolom kanan kartu ini adalah satu garis, bukan dua.
      expect(find.text('17:58'), findsOneWidget);
      expect(
        tester.getRect(find.text('17:58')).right,
        closeTo(countdownRight, 1),
        reason: 'jam dan countdown harus berbagi garis kanan yang sama',
      );

      // Kiri dan kanan tiap baris berbeda ukuran huruf, jadi perataan lewat
      // dasar kotak baris akan menggeser garis dasar hurufnya. Yang diukur di
      // sini adalah garis dasar sesungguhnya.
      expect(
        _baselineY(tester, find.text('SOLAT BERIKUTNYA')),
        closeTo(_baselineY(tester, find.text('17:58')), 0.5),
        reason: 'label dan jam harus duduk pada satu garis dasar',
      );
      expect(
        _baselineY(tester, find.text('Maghrib (besok)', findRichText: true)),
        closeTo(_baselineY(tester, find.text('23j 59m')), 0.5),
        reason: 'nama solat dan countdown harus duduk pada satu garis dasar',
      );

      // Sisi lain dari bug yang sama — nama solat terpotong elipsis — sengaja
      // tidak diuji di sini. flutter_test memakai font uji yang tiap glifnya
      // selebar satu em, jauh lebih lebar dari Inter, sehingga teks apa pun
      // akan terpotong pada lebar 320px terlepas dari benar atau tidaknya
      // tata letak. Assertion jarak di atas sudah menguji akar masalah yang
      // sama (pembagian ruang antar kolom) dengan cara yang tidak bergantung
      // pada lebar glif.
    });

    for (final scale in [1.0, 1.3, 2.0]) {
      for (final width in [320.0, 411.0]) {
        testWidgets('muat pada skala teks $scale di lebar $width', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          for (final theme in [AppTheme.dark, AppTheme.light]) {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  prayerTimesProvider.overrideWith(
                    () => _StubNotifier(worstCase),
                  ),
                ],
                child: MaterialApp(
                  theme: theme,
                  home: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: const Scaffold(body: PrayerTimerCard()),
                  ),
                ),
              ),
            );
            await tester.pump();

            expect(
              find.text('SOLAT BERIKUTNYA'),
              findsOneWidget,
              reason: 'baris hero harus benar-benar terender, bukan loading',
            );
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  });
}
