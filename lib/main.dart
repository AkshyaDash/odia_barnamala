import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/database/database_initializer.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed the SQLite database before the UI starts (idempotent — fast on
  // subsequent launches because the idempotency guard returns immediately).
  await DatabaseInitializer.initialize();

  // Lock to portrait only — toddler friendly
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Immersive mode — hide status/nav bars for full-screen feel
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ProviderScope(child: OdiaBarnamalaApp()));
}

class OdiaBarnamalaApp extends StatelessWidget {
  const OdiaBarnamalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odia Barnamala',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
