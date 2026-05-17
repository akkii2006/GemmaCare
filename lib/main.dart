import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/user_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/care_provider.dart';
import 'providers/emergency_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/model_download_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userProvider = UserProvider();
  final settingsProvider = SettingsProvider();
  final modelDownloadProvider = ModelDownloadProvider();
  final scanProvider = ScanProvider();

  await Future.wait([
    userProvider.init(),
    settingsProvider.init(),
    modelDownloadProvider.checkDownloaded(),
    scanProvider.init(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => userProvider),
        ChangeNotifierProvider(create: (_) => settingsProvider),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => scanProvider),
        ChangeNotifierProvider(create: (_) => CareProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => modelDownloadProvider),
      ],
      child: const GemmaCareApp(),
    ),
  );
}