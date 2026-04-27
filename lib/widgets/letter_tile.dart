import 'package:flutter/material.dart';

import '../models/letter.dart';
import '../screens/letter_trace_screen.dart';
import '../theme/app_theme.dart';

class LetterTile extends StatefulWidget {
  final OdiaLetter letter;

  const LetterTile({super.key, required this.letter});

  @override
  State<LetterTile> createState() => _LetterTileState();
}

class _LetterTileState extends State<LetterTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward(from: 0);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LetterTraceScreen(letter: widget.letter),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.letter.tileColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      widget.letter.character,
                      style: AppTheme.odiaLetterStyle(size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.letter.name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
