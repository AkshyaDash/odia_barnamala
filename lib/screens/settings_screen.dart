import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bhasha_database_helper.dart';
import '../theme/bhasha_design_system.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _authenticated = false;
  bool _pinExists = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final prefs = await SharedPreferences.getInstance();
    _pinExists = prefs.getString('parent_pin_hash') != null;
    setState(() => _loading = false);

    if (!_pinExists) {
      // First time: prompt to set PIN
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSetPinDialog();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showEnterPinDialog();
      });
    }
  }

  String _hashPin(String pin) {
    // Simple hash for PIN storage — not cryptographic, but sufficient
    // for a child-app parent gate
    return pin.hashCode.toRadixString(16);
  }

  Future<void> _showSetPinDialog() async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PinDialog(title: 'Set a 4-digit PIN'),
    );
    if (pin != null && pin.length == 4) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('parent_pin_hash', _hashPin(pin));
      if (mounted) setState(() => _authenticated = true);
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showEnterPinDialog() async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PinDialog(title: 'Enter parent PIN'),
    );
    if (pin != null) {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString('parent_pin_hash') ?? '';
      if (_hashPin(pin) == storedHash) {
        if (mounted) setState(() => _authenticated = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wrong PIN')),
          );
          Navigator.pop(context);
        }
      }
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: BhashaColors.scaffold,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_authenticated) {
      return const Scaffold(
        backgroundColor: BhashaColors.scaffold,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const _SettingsBody();
  }
}

// ---------------------------------------------------------------------------
// PIN dialog
// ---------------------------------------------------------------------------

class _PinDialog extends StatefulWidget {
  final String title;

  const _PinDialog({required this.title});

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BhashaSpacing.radiusLg),
      ),
      title: Text(
        widget.title,
        style: BhashaTextStyles.cardTitle.copyWith(
          fontSize: 16,
          color: BhashaColors.textPrimary,
        ),
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '4-digit PIN',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.length == 4) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Settings body (shown after PIN auth)
// ---------------------------------------------------------------------------

class _SettingsBody extends StatefulWidget {
  const _SettingsBody();

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  final _nameController = TextEditingController();
  String _ageGroup = '4-6 years';
  bool _soundEffects = true;
  bool _autoPlay = true;
  bool _showRoman = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('child_name') ?? '';
    _ageGroup = prefs.getString('age_group') ?? '4-6 years';
    _soundEffects = prefs.getBool('sound_effects') ?? true;
    _autoPlay = prefs.getBool('auto_play') ?? true;
    _showRoman = prefs.getBool('show_roman') ?? true;
    if (mounted) setState(() {});
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  Future<void> _showResetLanguageSheet() async {
    final db = DatabaseHelper.instance;
    final languages = await db.getAllLanguages();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset progress for a language',
              style: BhashaTextStyles.cardTitle.copyWith(
                fontSize: 16,
                color: BhashaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) => ListTile(
                  title: Text('${lang.script} ${lang.name}',
                      style: BhashaTextStyles.body),
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await db.resetProgressForLanguage(lang.id!);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        SnackBar(
                            content:
                                Text('${lang.name} progress reset')),
                      );
                    },
                    child: const Text('Reset'),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BhashaSpacing.radiusLg),
        ),
        title: const Text('Reset all progress?'),
        content: const Text(
          'This will erase all stars, quiz results, and streak data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.resetAllProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All progress reset')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BhashaColors.scaffold,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BhashaHeader(
              title: 'Parent zone',
              color: const Color(0xFF374151),
              onBack: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 1. Child profile
                const SectionLabel('Child profile'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Child's name",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _savePref('child_name', v),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _ageGroup,
                    decoration: const InputDecoration(
                      labelText: 'Age group',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: '4-6 years', child: Text('4-6 years')),
                      DropdownMenuItem(
                          value: '7-9 years', child: Text('7-9 years')),
                      DropdownMenuItem(
                          value: '10+ years', child: Text('10+ years')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _ageGroup = v);
                        _savePref('age_group', v);
                      }
                    },
                  ),
                ),

                const Divider(height: 32),

                // 2. App preferences
                const SectionLabel('App preferences'),
                SwitchListTile(
                  title: const Text('Sound effects',
                      style: BhashaTextStyles.body),
                  value: _soundEffects,
                  activeThumbColor: BhashaColors.primary,
                  onChanged: (v) {
                    setState(() => _soundEffects = v);
                    _savePref('sound_effects', v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto-play letter sound',
                      style: BhashaTextStyles.body),
                  value: _autoPlay,
                  activeThumbColor: BhashaColors.primary,
                  onChanged: (v) {
                    setState(() => _autoPlay = v);
                    _savePref('auto_play', v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Show romanization',
                      style: BhashaTextStyles.body),
                  value: _showRoman,
                  activeThumbColor: BhashaColors.primary,
                  onChanged: (v) {
                    setState(() => _showRoman = v);
                    _savePref('show_roman', v);
                  },
                ),

                const Divider(height: 32),

                // 3. Progress management
                const SectionLabel('Progress management'),
                ListTile(
                  title: const Text('Reset progress for a language',
                      style: BhashaTextStyles.body),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showResetLanguageSheet,
                ),
                ListTile(
                  title: Text(
                    'Reset all progress',
                    style: BhashaTextStyles.body.copyWith(
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: Color(0xFFEF4444)),
                  onTap: _showResetAllDialog,
                ),

                const Divider(height: 32),

                // 4. About
                const SectionLabel('About'),
                const ListTile(
                  title: Text('App version', style: BhashaTextStyles.body),
                  trailing: Text('1.0.0', style: BhashaTextStyles.bodySmall),
                ),
                const ListTile(
                  title: Text('Designed for Indian languages',
                      style: BhashaTextStyles.body),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No internet required. No data leaves your device.',
                    style: BhashaTextStyles.bodySmall,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
