import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers/providers.dart';
import '../../widgets/qibla/qibla_compass.dart';

/// Qibla Screen - live compass pointing to the Kaaba.
class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  @override
  void dispose() {
    FlutterQiblah().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(qiblaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kiblat')),
      body: switch (status) {
        QiblaStatus.checking => const Center(
          child: CircularProgressIndicator(),
        ),
        QiblaStatus.ready => const _QiblaCompassView(),
        QiblaStatus.noSensor => const _QiblaMessage(
          icon: Icons.sensors_off,
          message:
              'Perangkat Anda tidak memiliki sensor kompas (magnetometer).',
        ),
        QiblaStatus.locationDisabled => _QiblaMessage(
          icon: Icons.location_off,
          message: 'Layanan lokasi mati. Aktifkan GPS lalu coba lagi.',
          onAction: () => ref.read(qiblaProvider.notifier).retry(),
        ),
        QiblaStatus.permissionDenied => _QiblaMessage(
          icon: Icons.location_disabled,
          message: 'Izin lokasi diperlukan untuk menentukan arah kiblat.',
          onAction: () => ref.read(qiblaProvider.notifier).retry(),
        ),
        QiblaStatus.permissionDeniedForever => _QiblaMessage(
          icon: Icons.location_disabled,
          message:
              'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan aplikasi.',
          onAction: () => Geolocator.openAppSettings(),
          actionLabel: 'Buka Pengaturan',
          actionIcon: Icons.settings_outlined,
        ),
      },
    );
  }
}

class _QiblaCompassView extends StatelessWidget {
  const _QiblaCompassView();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _QiblaMessage(
            icon: Icons.error_outline,
            message:
                'Gagal membaca sensor kompas. Coba jauhkan perangkat dari '
                'benda logam atau magnet, lalu buka ulang halaman.',
          );
        }
        if (!snapshot.hasData) {
          return const _QiblaMessage(
            icon: Icons.sensors,
            message: 'Menunggu data sensor kompas...',
          );
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: QiblaCompass(direction: snapshot.data!)),
          ),
        );
      },
    );
  }
}

class _QiblaMessage extends StatelessWidget {
  const _QiblaMessage({
    required this.icon,
    required this.message,
    this.onAction,
    this.actionLabel = 'Coba lagi',
    this.actionIcon = Icons.refresh,
  });

  final IconData icon;
  final String message;

  /// Optional recovery action. When null, no button is shown (terminal state).
  final VoidCallback? onAction;
  final String actionLabel;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  icon,
                  size: 56,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon),
                  label: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
