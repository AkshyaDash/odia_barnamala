import 'package:flutter/material.dart';

import '../theme/bhasha_design_system.dart';

const String kRouteHome = '/home';
const String kRouteLetterGrid = '/letters';
const String kRouteTrace = '/trace';
const String kRouteQuiz = '/quiz';
const String kRouteWordExamples = '/words';
const String kRouteProgress = '/progress';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  late AnimationController _stripController;

  static const _scripts = ['ଅ', 'ह', 'ஆ', 'అ', 'ಕ', 'ক'];

  @override
  void initState() {
    super.initState();

    // Logo scale animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Fade in for app name
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    // Strip slide-up
    _stripController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 480 + (_scripts.length - 1) * 80),
    );

    // Start animations
    _logoController.forward().then((_) {
      _fadeController.forward();
      _stripController.forward();
    });

    // Navigate after 2500ms
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(kRouteHome);
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _stripController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BhashaColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            // Logo box
            ScaleTransition(
              scale: _logoScale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: BhashaColors.primary,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // App name
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'Bhasha Kids',
                style: BhashaTextStyles.appTitle.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'Learn all Indian alphabets!',
                style: BhashaTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            const Spacer(flex: 3),
            // Script strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_scripts.length, (i) {
                  final delay = i * 80;
                  final totalDuration =
                      480 + (_scripts.length - 1) * 80;
                  final start = delay / totalDuration;
                  final end = (delay + 480) / totalDuration;

                  return AnimatedBuilder(
                    animation: _stripController,
                    builder: (context, child) {
                      final t = Curves.easeOut.transform(
                        (((_stripController.value - start) / (end - start))
                                .clamp(0.0, 1.0)),
                      );
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - t)),
                        child: Opacity(
                          opacity: t,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _scripts[i],
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
