import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bhasha_database_helper.dart';
import '../services/language_purchase_service.dart';
import 'language_setup_progress_screen.dart';

class LanguageOnboardingScreen extends StatefulWidget {
  const LanguageOnboardingScreen({super.key});

  @override
  State<LanguageOnboardingScreen> createState() =>
      _LanguageOnboardingScreenState();
}

class _LanguageOnboardingScreenState extends State<LanguageOnboardingScreen> {
  static const _allLanguages = <Map<String, String>>[
    {'code': 'en',  'name': 'English',   'script': 'A',  'scriptType': 'Latin'},
    {'code': 'or',  'name': 'Odia',      'script': 'ଓ',  'scriptType': 'Odia'},
    {'code': 'hi',  'name': 'Hindi',     'script': 'ह',  'scriptType': 'Devanagari'},
    {'code': 'ta',  'name': 'Tamil',     'script': 'அ',  'scriptType': 'Tamil'},
    {'code': 'te',  'name': 'Telugu',    'script': 'అ',  'scriptType': 'Telugu'},
    {'code': 'kn',  'name': 'Kannada',   'script': 'ಕ',  'scriptType': 'Kannada'},
    {'code': 'ml',  'name': 'Malayalam', 'script': 'അ',  'scriptType': 'Malayalam'},
    {'code': 'bn',  'name': 'Bengali',   'script': 'ক',  'scriptType': 'Bengali'},
    {'code': 'gu',  'name': 'Gujarati',  'script': 'અ',  'scriptType': 'Gujarati'},
    {'code': 'pa',  'name': 'Punjabi',   'script': 'ਅ',  'scriptType': 'Gurmukhi'},
    {'code': 'mr',  'name': 'Marathi',   'script': 'अ',  'scriptType': 'Devanagari'},
    {'code': 'ur',  'name': 'Urdu',      'script': 'ا',  'scriptType': 'Nastaliq'},
    {'code': 'as',  'name': 'Assamese',  'script': 'অ',  'scriptType': 'Assamese'},
    // Coming soon — on currency notes, planned for a future update
    {'code': 'ks',  'name': 'Kashmiri',  'script': 'कश्', 'scriptType': 'Perso-Arabic'},
    {'code': 'kok', 'name': 'Konkani',   'script': 'क',  'scriptType': 'Devanagari'},
    {'code': 'ne',  'name': 'Nepali',    'script': 'न',  'scriptType': 'Devanagari'},
    {'code': 'sa',  'name': 'Sanskrit',  'script': 'स',  'scriptType': 'Devanagari'},
  ];

  static const _saffron = Color(0xFFFF6B1A);

  final _pageController = PageController();
  int _currentPage = 0;

  Set<String> _dbCodes = {};
  Set<String> _alreadyOwnedCodes = {};
  final Set<String> _selectedPaidCodes = {};
  bool _isProcessing = false;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDbCodes();
    _alreadyOwnedCodes = {
      ...LanguagePurchaseService.freeCodes,
      ...LanguagePurchaseService.instance.purchasedCodes,
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDbCodes() async {
    final langs = await DatabaseHelper.instance.getAllLanguages();
    if (!mounted) return;
    setState(() => _dbCodes = langs.map((l) => l.code).toSet());
  }

  void _onTapLanguage(String code) {
    if (LanguagePurchaseService.freeCodes.contains(code)) return;
    if (_alreadyOwnedCodes.contains(code)) return;
    if (!_dbCodes.contains(code)) return; // coming soon, not tappable
    setState(() {
      if (_selectedPaidCodes.contains(code)) {
        _selectedPaidCodes.remove(code);
      } else {
        _selectedPaidCodes.add(code);
      }
    });
  }

  // Skip language picker entirely — mark onboarding done and go home
  Future<void> _onDecideLater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  // Purchase all selected languages then proceed to the setup progress screen
  Future<void> _onGetStarted() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    for (final code in _selectedPaidCodes) {
      await LanguagePurchaseService.instance.purchaseLanguage(code);
    }

    final allLangs = await DatabaseHelper.instance.getAllLanguages();
    final selectedLangs = allLangs
        .where((l) => LanguagePurchaseService.instance.isUnlocked(l.code))
        .toList();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LanguageSetupProgressScreen(selectedLanguages: selectedLangs),
      ),
    );
  }

  List<Map<String, String>> get _filteredLanguages {
    if (_searchQuery.isEmpty) return _allLanguages;
    final q = _searchQuery.toLowerCase();
    return _allLanguages
        .where((l) =>
            l['name']!.toLowerCase().contains(q) ||
            l['scriptType']!.toLowerCase().contains(q) ||
            l['script']!.contains(_searchQuery))
        .toList();
  }

  int get _paidSelectedCount => _selectedPaidCodes.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _SplashPage(
                onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
              ),
              _WelcomePage(
                onChoose: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
                onDecideLater: _onDecideLater,
              ),
              _LanguageSelectPage(
                allLanguages: _filteredLanguages,
                dbCodes: _dbCodes,
                alreadyOwnedCodes: _alreadyOwnedCodes,
                selectedPaidCodes: _selectedPaidCodes,
                isProcessing: _isProcessing,
                searchQuery: _searchQuery,
                paidSelectedCount: _paidSelectedCount,
                onSearch: (q) => setState(() => _searchQuery = q),
                onTapLanguage: _onTapLanguage,
                onBack: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
                onGetStarted: _onGetStarted,
              ),
            ],
          ),
          // Page indicator dots — hidden on the language picker (page 2) so
          // they don't overlap the sticky footer.
          if (_currentPage < 2)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? _saffron
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 0 — Splash
// ---------------------------------------------------------------------------

class _SplashPage extends StatefulWidget {
  final VoidCallback onTap;
  const _SplashPage({required this.onTap});

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  static const _saffron = Color(0xFFFF6B1A);
  static const _navy = Color(0xFF000080);

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_saffron, Color(0xFFE8500A), _navy],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _RangoliPainter())),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: child,
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Text('🌺', style: TextStyle(fontSize: 60)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Bhasha Kids',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LEARN · WRITE · SPEAK',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '17 Indian languages · Ages 3–8',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const Spacer(),
                  _PulseDots(),
                  const SizedBox(height: 12),
                  Text(
                    'Tap anywhere to begin',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDots extends StatefulWidget {
  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
          final scale = 1.0 + 0.4 * math.sin(phase * math.pi);
          final opacity =
              0.35 + 0.65 * math.sin(phase * math.pi).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8 * scale,
            height: 8 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: opacity),
            ),
          );
        }),
      ),
    );
  }
}

class _RangoliPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (final r in [60.0, 120.0, 180.0, 240.0, 300.0]) {
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ---------------------------------------------------------------------------
// Page 1 — Welcome
// ---------------------------------------------------------------------------

class _WelcomePage extends StatefulWidget {
  final VoidCallback onChoose;
  final VoidCallback onDecideLater;

  const _WelcomePage({
    required this.onChoose,
    required this.onDecideLater,
  });

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _saffron = Color(0xFFFF6B1A);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _animatedCard(int index, Widget card) {
    final start = index * 0.18;
    final slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, (start + 0.55).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      ),
    );
    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      ),
    );
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, slideAnim.value),
          child: card,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      color: const Color(0xFFFFFDF7),
      child: Column(
        children: [
          // Curved saffron header
          ClipPath(
            clipper: _CurvedBottomClipper(),
            child: Container(
              color: _saffron,
              padding: EdgeInsets.fromLTRB(
                28,
                MediaQuery.of(context).padding.top + 28,
                28,
                52,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Learn to read & write\nin your mother tongue',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Feature cards + CTAs
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 24),
              child: Column(
                children: [
                  _animatedCard(
                    0,
                    const _FeatureCard(
                      emoji: '🔊',
                      bgColor: Color(0xFFFFF0E6),
                      title: 'Hear every letter',
                      subtitle:
                          'Tap any letter and hear it spoken clearly in the right accent',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _animatedCard(
                    1,
                    const _FeatureCard(
                      emoji: '✍️',
                      bgColor: Color(0xFFE8F5E8),
                      title: 'Trace & write',
                      subtitle:
                          'Follow guided stroke paths to learn the correct way to form each letter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _animatedCard(
                    2,
                    const _FeatureCard(
                      emoji: '⭐',
                      bgColor: Color(0xFFEAF0FF),
                      title: 'Earn stars',
                      subtitle:
                          'Complete letters to unlock rewards and track your progress',
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _saffron,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: widget.onChoose,
                      child: const Text(
                        'Choose your language →',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFDDD8CC), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: widget.onDecideLater,
                      child: const Text(
                        "I'll decide later",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C4A1E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final Color bgColor;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.emoji,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE8DF), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1206),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A8060),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ---------------------------------------------------------------------------
// Page 2 — Language Select
// ---------------------------------------------------------------------------

class _LanguageSelectPage extends StatelessWidget {
  final List<Map<String, String>> allLanguages;
  final Set<String> dbCodes;
  final Set<String> alreadyOwnedCodes;
  final Set<String> selectedPaidCodes;
  final bool isProcessing;
  final String searchQuery;
  final int paidSelectedCount;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onTapLanguage;
  final VoidCallback onBack;
  final VoidCallback onGetStarted;

  const _LanguageSelectPage({
    required this.allLanguages,
    required this.dbCodes,
    required this.alreadyOwnedCodes,
    required this.selectedPaidCodes,
    required this.isProcessing,
    required this.searchQuery,
    required this.paidSelectedCount,
    required this.onSearch,
    required this.onTapLanguage,
    required this.onBack,
    required this.onGetStarted,
  });

  static const _saffron = Color(0xFFFF6B1A);
  static const _green = Color(0xFF138808);

  List<Map<String, String>> get _freeLanguages => allLanguages
      .where((l) => LanguagePurchaseService.freeCodes.contains(l['code']))
      .toList();

  List<Map<String, String>> get _paidLanguages => allLanguages
      .where((l) => !LanguagePurchaseService.freeCodes.contains(l['code']))
      .toList();

  @override
  Widget build(BuildContext context) {
    final totalCost = paidSelectedCount * 199;

    return Container(
      color: const Color(0xFFFAFAF7),
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 8,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pick your\nlanguages',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1206),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'English & Odia are free. Unlock more for ₹199 each.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9A8060)),
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search language…',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Color(0xFFEDE8DF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Color(0xFFEDE8DF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: _saffron),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Language list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              children: [
                if (_freeLanguages.isNotEmpty) ...[
                  _groupLabel('Always Free'),
                  ..._freeLanguages.map((l) => _LanguageRow(
                        code: l['code']!,
                        name: l['name']!,
                        script: l['script']!,
                        scriptType: l['scriptType']!,
                        isFree: true,
                        isOwned: false,
                        isSelected: false,
                        isInDb: dbCodes.contains(l['code']),
                        onTap: () {},
                      )),
                ],
                if (_paidLanguages.isNotEmpty) ...[
                  _groupLabel('₹199 per language'),
                  ..._paidLanguages.map((l) {
                    final code = l['code']!;
                    return _LanguageRow(
                      code: code,
                      name: l['name']!,
                      script: l['script']!,
                      scriptType: l['scriptType']!,
                      isFree: false,
                      isOwned: alreadyOwnedCodes.contains(code),
                      isSelected: selectedPaidCodes.contains(code),
                      isInDb: dbCodes.contains(code),
                      onTap: () => onTapLanguage(code),
                    );
                  }),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Sticky footer
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEDE8DF))),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (paidSelectedCount == 0)
                      const Text(
                        'Only free languages selected',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF9A8060)),
                      )
                    else
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: '$paidSelectedCount',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1206),
                            ),
                          ),
                          TextSpan(
                            text:
                                ' paid language${paidSelectedCount == 1 ? "" : "s"} selected',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF9A8060)),
                          ),
                        ]),
                      ),
                    if (totalCost > 0)
                      Text(
                        '₹$totalCost',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _saffron,
                        ),
                      )
                    else
                      const Text(
                        'Free',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _green,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _saffron,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: isProcessing ? null : onGetStarted,
                    child: isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Start learning →',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.5,
            color: Color(0xFF9A8060),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Language row widget
// ---------------------------------------------------------------------------

class _LanguageRow extends StatelessWidget {
  final String code;
  final String name;
  final String script;
  final String scriptType;
  final bool isFree;
  final bool isOwned;    // already purchased in a prior session
  final bool isSelected; // user toggled this in the current cart
  final bool isInDb;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.code,
    required this.name,
    required this.script,
    required this.scriptType,
    required this.isFree,
    required this.isOwned,
    required this.isSelected,
    required this.isInDb,
    required this.onTap,
  });

  static const _saffron = Color(0xFFFF6B1A);
  static const _saffronPale = Color(0xFFFFF0E6);
  static const _green = Color(0xFF138808);
  static const _greenPale = Color(0xFFE8F5E8);

  bool get _isActive => isFree || isOwned || isSelected;

  @override
  Widget build(BuildContext context) {
    final comingSoon = !isInDb && !isFree;

    Color borderColor;
    Color bgColor;
    if (comingSoon) {
      borderColor = const Color(0xFFE5DED0);
      bgColor = const Color(0xFFF5F0E8);
    } else if (isFree) {
      borderColor = _green;
      bgColor = _greenPale;
    } else if (isOwned || isSelected) {
      borderColor = _saffron;
      bgColor = _saffronPale;
    } else {
      borderColor = const Color(0xFFEDE8DF);
      bgColor = Colors.white;
    }

    return GestureDetector(
      onTap: (comingSoon || isFree || isOwned) ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Script tile
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  script,
                  style: TextStyle(
                    fontSize: 22,
                    color: comingSoon ? const Color(0xFFBBB0A0) : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + script type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: comingSoon
                          ? const Color(0xFFB0A090)
                          : isFree
                              ? _green
                              : (isOwned || isSelected)
                                  ? _saffron
                                  : const Color(0xFF1A1206),
                    ),
                  ),
                  Text(
                    scriptType,
                    style: TextStyle(
                      fontSize: 11,
                      color: comingSoon
                          ? const Color(0xFFCCC0B0)
                          : const Color(0xFF9A8060),
                    ),
                  ),
                ],
              ),
            ),
            // Right-side badge
            if (comingSoon)
              _pill('Soon', Colors.grey.shade400, Colors.white)
            else if (isFree)
              _pill('FREE', _green, Colors.white)
            else if (!isOwned && !isSelected)
              _pill('₹199', const Color(0xFF9A8060), Colors.white),
            const SizedBox(width: 8),
            // Checkbox circle
            if (!comingSoon)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isActive
                      ? (isFree ? _green : _saffron)
                      : Colors.transparent,
                  border: _isActive
                      ? null
                      : Border.all(color: const Color(0xFFDDD8CC), width: 2),
                ),
                child: _isActive
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg),
        ),
      );
}
