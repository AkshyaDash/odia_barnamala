import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'letter_grid_screen.dart';
import 'rewards_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 1; // Start on Learn screen

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _WelcomeTab(),
      LetterGridScreen(
        onBack: () => setState(() => _selectedIndex = 0),
      ),
      const RewardsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.navBar,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavButton(
                  icon: Icons.home_rounded,
                  color: const Color(0xFFFF9999),
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavButton(
                  icon: Icons.auto_stories_rounded,
                  color: const Color(0xFF99CCFF),
                  selected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavButton(
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFFFD700),
                  selected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 72,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 44,
          color: selected ? color : Colors.grey.shade400,
        ),
      ),
    );
  }
}

class _WelcomeTab extends StatelessWidget {
  const _WelcomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ଓଡ଼ିଆ',
                style: AppTheme.odiaLetterStyle(size: 72),
              ),
              const SizedBox(height: 8),
              Text(
                'ବର୍ଣ୍ଣମାଳା',
                style: AppTheme.odiaLetterStyle(size: 48),
              ),
              const SizedBox(height: 48),
              // Large animated arrow pointing to Learn tab
              const Icon(Icons.arrow_downward_rounded,
                  size: 80, color: Color(0xFF99CCFF)),
            ],
          ),
        ),
      ),
    );
  }
}
