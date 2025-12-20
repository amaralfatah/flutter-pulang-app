import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize Notification Service
  await NotificationService().init();

  runApp(const ProviderScope(child: PulangApp()));
}
