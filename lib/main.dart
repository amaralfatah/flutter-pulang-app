import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/router.dart' as app_router;
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize Notification Service
  await NotificationService().init();

  // Read once, synchronously usable by router's redirect from here on —
  // GoRouter needs this decided before the very first route match.
  final preferencesService = PreferencesService();
  await preferencesService.init();
  app_router.onboardingCompleted = await preferencesService
      .isOnboardingCompleted();

  runApp(const ProviderScope(child: PulangApp()));
}
