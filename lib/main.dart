import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/bhasha_database_helper.dart';
import 'models/language.dart';
import 'models/letter_new.dart';
import 'providers/bhasha_progress_provider.dart';
import 'providers/home_provider.dart';
import 'providers/quiz_provider.dart';
import 'screens/bhasha_home_screen.dart';
import 'screens/letter_grid_screen.dart';
import 'screens/letter_trace_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/word_examples_screen.dart';
import 'theme/bhasha_design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = DatabaseHelper.instance;
  await db.seedDatabase();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()..loadHomeData()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(
            create: (_) => ProgressProvider()..loadProgress()),
      ],
      child: MaterialApp(
        title: 'Bhasha Kids',
        debugShowCheckedModeBanner: false,
        theme: bhashaTheme(),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          kRouteHome: (_) => const BhashaHomeScreen(),
          kRouteLetterGrid: (ctx) => LetterGridScreen(
              language:
                  ModalRoute.of(ctx)!.settings.arguments as Language),
          kRouteTrace: (ctx) => LetterTraceScreen(
              letter: ModalRoute.of(ctx)!.settings.arguments as Letter),
          kRouteQuiz: (ctx) => QuizScreen(
              language:
                  ModalRoute.of(ctx)!.settings.arguments as Language),
          kRouteWordExamples: (ctx) => WordExamplesScreen(
              language:
                  ModalRoute.of(ctx)!.settings.arguments as Language),
          kRouteProgress: (_) => const ProgressScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    ),
  );
}
