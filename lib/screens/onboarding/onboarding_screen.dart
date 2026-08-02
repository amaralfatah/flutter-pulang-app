import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart' as app_router;
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/patterns/pattern_painters.dart';

/// Alur pertama kali membuka aplikasi: pilih kota, lalu izinkan notifikasi.
/// Keduanya bisa dilewati — tidak ada yang wajib untuk memakai aplikasi,
/// dan keduanya tetap bisa diubah lagi lewat Pengaturan.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  static const _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    await ref.read(preferencesServiceProvider).setOnboardingCompleted();
    app_router.onboardingCompleted = true;
    if (!mounted) return;
    context.go(app_router.AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(onNext: () => _goTo(1)),
                  _CityPage(
                    onNext: () => _goTo(2),
                    onSkip: () => _goTo(2),
                  ),
                  _NotificationPage(onFinish: _finish),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: colorScheme.onPrimary,
                  opacity: 0.15,
                ),
                child: Icon(
                  Icons.mosque_rounded,
                  size: 56,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Selamat datang di Pulang',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Catat solat harianmu, pantau hutang qadha, dan lihat konsistensi '
            'dari waktu ke waktu. Dua langkah singkat dulu sebelum mulai.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );
  }
}

class _CityPage extends ConsumerStatefulWidget {
  const _CityPage({required this.onNext, required this.onSkip});

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  ConsumerState<_CityPage> createState() => _CityPageState();
}

class _CityPageState extends ConsumerState<_CityPage> {
  static const _minQueryLength = 3;

  final _searchController = TextEditingController();
  List<City> _cities = [];
  bool _isSearching = false;
  String? _selectedCityName;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < _minQueryLength) {
      setState(() => _cities = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().length < _minQueryLength) return;
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final cities = await ref
          .read(prayerApiServiceProvider)
          .searchCities(query);
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _selectCity(String id, String name) async {
    await ref.read(settingsProvider.notifier).setCity(id: id, name: name);
    await ref.read(prayerTimesProvider.notifier).refresh();
    unawaited(
      ref.read(prayerApiServiceProvider).prefetchPrayerTimes(cityId: id),
    );
    if (!mounted) return;
    setState(() => _selectedCityName = name);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _searchController.text.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_rounded, size: 40, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Pilih kota kamu',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Dipakai untuk menghitung jadwal solat harian. Bisa diganti kapan '
            'saja lewat Pengaturan.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          if (_selectedCityName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedCityName!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedCityName = null),
                    child: const Text('Ganti'),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari nama kota (min. $_minQueryLength huruf)',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
              ),
              onChanged: _onQueryChanged,
              onSubmitted: _search,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: colorScheme.error)),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: query.length >= _minQueryLength && _cities.isEmpty && !_isSearching
                  ? Center(
                      child: Text(
                        'Kota tidak ditemukan',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _cities.length,
                      itemBuilder: (context, index) {
                        final city = _cities[index];
                        return ListTile(
                          title: Text(city.name),
                          onTap: () => _selectCity(city.id, city.name),
                        );
                      },
                    ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.onSkip,
                  child: const Text('Lewati'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _selectedCityName == null ? null : widget.onNext,
                  child: const Text('Lanjut'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationPage extends ConsumerStatefulWidget {
  const _NotificationPage({required this.onFinish});

  final VoidCallback onFinish;

  @override
  ConsumerState<_NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<_NotificationPage> {
  bool _isRequesting = false;
  bool? _granted;

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermissions();
    await NotificationService.scheduleDailyReschedule();
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _granted = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_active_rounded,
            size: 40,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aktifkan pengingat solat',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Pulang mengingatkanmu tepat saat masuk waktu solat. Kamu bisa '
            'mengatur ulang ini kapan saja di Pengaturan.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          if (_granted == false)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Izin belum diberikan. Kamu tetap bisa lanjut — nyalakan lagi '
                'lewat Pengaturan kapan pun kamu siap.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (_granted != true)
            FilledButton.icon(
              onPressed: _isRequesting ? null : _requestPermission,
              icon: _isRequesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.notifications_rounded),
              label: const Text('Aktifkan Notifikasi'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Notifikasi aktif',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: widget.onFinish,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(_granted == true ? 'Selesai' : 'Lewati & Selesai'),
          ),
        ],
      ),
    );
  }
}
