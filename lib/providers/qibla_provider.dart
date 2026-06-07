import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// High-level readiness state of the Qibla feature.
enum QiblaStatus {
  checking,
  ready,
  noSensor,
  locationDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// Runs the one-time sensor-support and location-permission checks required
/// before the compass stream can be used.
class QiblaNotifier extends Notifier<QiblaStatus> {
  @override
  QiblaStatus build() {
    _init();
    return QiblaStatus.checking;
  }

  Future<void> _init() async {
    final hasSensor = await FlutterQiblah.androidDeviceSensorSupport() ?? false;
    if (!hasSensor) {
      state = QiblaStatus.noSensor;
      return;
    }

    var location = await FlutterQiblah.checkLocationStatus();
    if (location.status == LocationPermission.denied) {
      await FlutterQiblah.requestPermissions();
      location = await FlutterQiblah.checkLocationStatus();
    }

    if (!location.enabled) {
      state = QiblaStatus.locationDisabled;
      return;
    }

    switch (location.status) {
      case LocationPermission.denied:
        state = QiblaStatus.permissionDenied;
      case LocationPermission.deniedForever:
        state = QiblaStatus.permissionDeniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        state = QiblaStatus.ready;
      case LocationPermission.unableToDetermine:
        state = QiblaStatus.permissionDenied;
    }
  }

  /// Re-run the checks. Used by the "Coba lagi" button.
  Future<void> retry() async {
    state = QiblaStatus.checking;
    await _init();
  }
}

final qiblaProvider = NotifierProvider<QiblaNotifier, QiblaStatus>(
  QiblaNotifier.new,
);
