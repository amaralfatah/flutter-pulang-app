import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        QiblaStatus.checking => const Center(child: CircularProgressIndicator()),
        QiblaStatus.ready => const _QiblaCompassView(),
        QiblaStatus.noSensor => const _QiblaMessage(
          icon: Icons.sensors_off,
          message:
              'Perangkat Anda tidak memiliki sensor kompas (magnetometer).',
        ),
        QiblaStatus.locationDisabled => _QiblaMessage(
          icon: Icons.location_off,
          message: 'Layanan lokasi mati. Aktifkan GPS lalu coba lagi.',
          onRetry: () => ref.read(qiblaProvider.notifier).retry(),
        ),
        QiblaStatus.permissionDenied => _QiblaMessage(
          icon: Icons.location_disabled,
          message: 'Izin lokasi diperlukan untuk menentukan arah kiblat.',
          onRetry: () => ref.read(qiblaProvider.notifier).retry(),
        ),
        QiblaStatus.permissionDeniedForever => const _QiblaMessage(
          icon: Icons.location_disabled,
          message:
              'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan aplikasi.',
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
        if (!snapshot.hasData) {
          return const Center(child: Text('Menunggu data sensor...'));
        }
        return Center(child: QiblaCompass(direction: snapshot.data!));
      },
    );
  }
}

class _QiblaMessage extends StatelessWidget {
  const _QiblaMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
