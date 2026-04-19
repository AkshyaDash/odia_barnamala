import 'package:flutter/material.dart';

/// Renders the letter-tracing canvas.
///
/// The guide is drawn by rendering the actual [character] glyph using
/// Flutter's TextPainter with two layers:
///   1. A thick stroke paint  → forms the outer edges of the tracing track.
///   2. A lighter fill paint  → fills the track interior.
///
/// This guarantees the guide always looks exactly like the letter,
/// regardless of which character is selected.
class LetterTracePainter extends CustomPainter {
  final String character;
  final List<List<Offset>> drawnStrokes;

  const LetterTracePainter({
    required this.character,
    required this.drawnStrokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGuide(canvas, size);
    _drawUserStrokes(canvas, size);
  }

  // ─── Guide rendering ────────────────────────────────────────────────────────

  void _drawGuide(Canvas canvas, Size size) {
    final fontSize = size.shortestSide * 0.66;

    // Layer 1 — outer shadow ring (soft blur behind the track).
    _paintText(
      canvas,
      size,
      fontSize,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 52.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Layer 2 — thick mid-gray stroke → the visible track border.
    _paintText(
      canvas,
      size,
      fontSize,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 42.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFCCCCCC),
    );

    // Layer 3 — lighter fill → the track interior.
    _paintText(
      canvas,
      size,
      fontSize,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFE8E8E8),
    );

    // Layer 4 — thin dashed-style center line using a narrow stroke.
    _paintText(
      canvas,
      size,
      fontSize,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFBBBBBB),
    );
  }

  /// Paints [character] centred on the canvas using the provided [paint] as
  /// the foreground (via TextStyle.foreground).
  void _paintText(Canvas canvas, Size size, double fontSize, Paint paint) {
    final tp = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(
          fontFamily: 'NotoSansOriya',
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout(maxWidth: size.width);
    tp.paint(
      canvas,
      Offset(
        (size.width - tp.width) / 2,
        (size.height - tp.height) / 2,
      ),
    );
  }

  // ─── User stroke rendering ───────────────────────────────────────────────

  void _drawUserStrokes(Canvas canvas, Size size) {
    final inkPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 22.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in drawnStrokes) {
      if (stroke.isEmpty) continue;
      _drawPolyline(canvas, stroke, inkPaint);
    }

    // Glowing brush-tip at the last drawn point.
    if (drawnStrokes.isNotEmpty && drawnStrokes.last.isNotEmpty) {
      _drawGlowingTip(canvas, drawnStrokes.last.last);
    }
  }

  void _drawPolyline(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.length < 2) {
      if (pts.isNotEmpty) {
        canvas.drawCircle(pts.first, paint.strokeWidth / 2, paint);
      }
      return;
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawGlowingTip(Canvas canvas, Offset center) {
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        center,
        10.0 * i,
        Paint()
          ..color = Colors.orangeAccent.withValues(alpha: 0.15 / i)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawCircle(center, 10, Paint()..color = Colors.orangeAccent);
  }

  @override
  bool shouldRepaint(LetterTracePainter old) =>
      old.character != character || old.drawnStrokes != drawnStrokes;
}
