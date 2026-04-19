import 'package:flutter/material.dart';

// Stroke paths for each Odia letter.
// Values are normalized [0.0, 1.0] — the painter scales them to canvas size.
// Each letter maps to a list of strokes; each stroke is a list of control
// points that are fed through a Catmull-Rom spline to produce a smooth curve.

/// Interpolates control points using a Catmull-Rom spline.
/// Returns a dense list of Offset suitable for drawing as a polyline.
List<Offset> catmullRomSpline(List<Offset> pts, {int steps = 16}) {
  if (pts.length < 2) return List.of(pts);
  final result = <Offset>[];
  // Phantom duplicate at each end so first/last segments are handled.
  final p = [pts.first, ...pts, pts.last];
  for (int i = 1; i < p.length - 2; i++) {
    final p0 = p[i - 1];
    final p1 = p[i];
    final p2 = p[i + 1];
    final p3 = p[i + 2];
    for (int j = 0; j <= steps; j++) {
      final t = j / steps;
      final t2 = t * t;
      final t3 = t2 * t;
      final x = 0.5 *
          ((2 * p1.dx) +
              (-p0.dx + p2.dx) * t +
              (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
              (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);
      final y = 0.5 *
          ((2 * p1.dy) +
              (-p0.dy + p2.dy) * t +
              (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
              (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);
      result.add(Offset(x, y));
    }
  }
  return result;
}

List<Offset> _s(List<Offset> pts) => catmullRomSpline(pts);

// ─── Vowel paths ────────────────────────────────────────────────────────────

final List<List<Offset>> _pathA = [
  _s([
    const Offset(0.63, 0.25), const Offset(0.50, 0.16), const Offset(0.33, 0.20),
    const Offset(0.24, 0.36), const Offset(0.28, 0.50), const Offset(0.46, 0.52),
    const Offset(0.60, 0.48), const Offset(0.66, 0.58), const Offset(0.58, 0.72),
    const Offset(0.40, 0.76), const Offset(0.26, 0.68),
  ]),
];

final List<List<Offset>> _pathAa = [
  _s([
    const Offset(0.56, 0.25), const Offset(0.44, 0.16), const Offset(0.28, 0.20),
    const Offset(0.20, 0.36), const Offset(0.24, 0.50), const Offset(0.42, 0.52),
    const Offset(0.54, 0.48), const Offset(0.60, 0.58), const Offset(0.52, 0.72),
    const Offset(0.34, 0.76), const Offset(0.20, 0.68),
  ]),
  _s([const Offset(0.74, 0.20), const Offset(0.74, 0.78)]),
];

final List<List<Offset>> _pathI = [
  _s([
    const Offset(0.50, 0.22), const Offset(0.64, 0.34), const Offset(0.50, 0.48),
    const Offset(0.62, 0.62), const Offset(0.48, 0.76),
  ]),
];

final List<List<Offset>> _pathIi = [
  _s([
    const Offset(0.38, 0.28), const Offset(0.52, 0.20), const Offset(0.66, 0.26),
    const Offset(0.62, 0.40), const Offset(0.48, 0.50), const Offset(0.60, 0.64),
    const Offset(0.46, 0.76),
  ]),
];

final List<List<Offset>> _pathU = [
  _s([
    const Offset(0.65, 0.22), const Offset(0.65, 0.60), const Offset(0.55, 0.72),
    const Offset(0.40, 0.74), const Offset(0.28, 0.64), const Offset(0.26, 0.46),
    const Offset(0.38, 0.30), const Offset(0.54, 0.22), const Offset(0.65, 0.26),
  ]),
];

final List<List<Offset>> _pathUu = [
  _s([
    const Offset(0.60, 0.22), const Offset(0.60, 0.58), const Offset(0.50, 0.70),
    const Offset(0.38, 0.72), const Offset(0.26, 0.62), const Offset(0.24, 0.44),
    const Offset(0.36, 0.28), const Offset(0.52, 0.22), const Offset(0.62, 0.26),
  ]),
  _s([const Offset(0.60, 0.68), const Offset(0.70, 0.78), const Offset(0.62, 0.86)]),
];

final List<List<Offset>> _pathRu = [
  _s([const Offset(0.50, 0.22), const Offset(0.50, 0.78)]),
  _s([
    const Offset(0.36, 0.46), const Offset(0.50, 0.44), const Offset(0.66, 0.36),
    const Offset(0.66, 0.24), const Offset(0.52, 0.20), const Offset(0.38, 0.26),
  ]),
  _s([const Offset(0.34, 0.76), const Offset(0.66, 0.76)]),
];

final List<List<Offset>> _pathE = [
  _s([
    const Offset(0.64, 0.28), const Offset(0.50, 0.20), const Offset(0.36, 0.28),
    const Offset(0.28, 0.44), const Offset(0.36, 0.56), const Offset(0.54, 0.58),
    const Offset(0.66, 0.68), const Offset(0.52, 0.76), const Offset(0.34, 0.74),
  ]),
];

final List<List<Offset>> _pathAi = [
  _s([
    const Offset(0.60, 0.28), const Offset(0.46, 0.20), const Offset(0.32, 0.28),
    const Offset(0.24, 0.44), const Offset(0.32, 0.56), const Offset(0.50, 0.58),
    const Offset(0.62, 0.68), const Offset(0.48, 0.76), const Offset(0.30, 0.74),
  ]),
  _s([const Offset(0.54, 0.22), const Offset(0.66, 0.16), const Offset(0.74, 0.24)]),
];

final List<List<Offset>> _pathO = [
  _s([
    const Offset(0.30, 0.50), const Offset(0.30, 0.28), const Offset(0.50, 0.18),
    const Offset(0.70, 0.28), const Offset(0.74, 0.50), const Offset(0.62, 0.70),
    const Offset(0.44, 0.78), const Offset(0.28, 0.68), const Offset(0.28, 0.50),
  ]),
];

final List<List<Offset>> _pathAu = [
  _s([
    const Offset(0.26, 0.48), const Offset(0.26, 0.26), const Offset(0.46, 0.16),
    const Offset(0.64, 0.26), const Offset(0.68, 0.48), const Offset(0.56, 0.68),
    const Offset(0.38, 0.76), const Offset(0.24, 0.64), const Offset(0.24, 0.48),
  ]),
  _s([
    const Offset(0.68, 0.34), const Offset(0.78, 0.34),
    const Offset(0.80, 0.56), const Offset(0.70, 0.64),
  ]),
];

// ─── Consonant paths ─────────────────────────────────────────────────────────

final List<List<Offset>> _pathKa = [
  _s([
    const Offset(0.50, 0.22), const Offset(0.36, 0.22), const Offset(0.26, 0.34),
    const Offset(0.24, 0.50), const Offset(0.30, 0.64), const Offset(0.44, 0.72),
    const Offset(0.60, 0.68), const Offset(0.68, 0.54), const Offset(0.64, 0.40),
    const Offset(0.50, 0.34), const Offset(0.36, 0.38),
  ]),
];

final List<List<Offset>> _pathKha = [
  _s([
    const Offset(0.50, 0.22), const Offset(0.36, 0.22), const Offset(0.26, 0.34),
    const Offset(0.24, 0.50), const Offset(0.30, 0.64), const Offset(0.44, 0.72),
    const Offset(0.58, 0.68), const Offset(0.66, 0.54), const Offset(0.62, 0.40),
    const Offset(0.48, 0.34), const Offset(0.36, 0.38),
  ]),
  _s([const Offset(0.66, 0.22), const Offset(0.66, 0.78)]),
];

final List<List<Offset>> _pathGa = [
  _s([
    const Offset(0.68, 0.40), const Offset(0.60, 0.22), const Offset(0.42, 0.20),
    const Offset(0.28, 0.34), const Offset(0.26, 0.54), const Offset(0.36, 0.70),
    const Offset(0.54, 0.76), const Offset(0.68, 0.66), const Offset(0.70, 0.48),
    const Offset(0.60, 0.38), const Offset(0.44, 0.38),
  ]),
];

final List<List<Offset>> _pathGha = [
  _s([
    const Offset(0.62, 0.38), const Offset(0.54, 0.20), const Offset(0.38, 0.18),
    const Offset(0.24, 0.32), const Offset(0.22, 0.52), const Offset(0.32, 0.68),
    const Offset(0.50, 0.74), const Offset(0.64, 0.64), const Offset(0.66, 0.46),
    const Offset(0.56, 0.36), const Offset(0.42, 0.36),
  ]),
  _s([const Offset(0.68, 0.30), const Offset(0.76, 0.22), const Offset(0.78, 0.36)]),
];

final List<List<Offset>> _pathNga = [
  _s([
    const Offset(0.50, 0.30), const Offset(0.38, 0.26), const Offset(0.28, 0.38),
    const Offset(0.30, 0.52), const Offset(0.44, 0.60), const Offset(0.58, 0.54),
    const Offset(0.62, 0.40), const Offset(0.54, 0.30),
  ]),
  _s([const Offset(0.50, 0.60), const Offset(0.50, 0.78)]),
];

final List<List<Offset>> _pathCha = [
  _s([
    const Offset(0.64, 0.26), const Offset(0.48, 0.18), const Offset(0.32, 0.26),
    const Offset(0.26, 0.42), const Offset(0.34, 0.54), const Offset(0.52, 0.56),
    const Offset(0.64, 0.66), const Offset(0.54, 0.78), const Offset(0.34, 0.76),
    const Offset(0.24, 0.64),
  ]),
];

final List<List<Offset>> _pathChha = [
  _s([
    const Offset(0.60, 0.26), const Offset(0.44, 0.18), const Offset(0.28, 0.26),
    const Offset(0.22, 0.42), const Offset(0.30, 0.54), const Offset(0.48, 0.56),
    const Offset(0.60, 0.66), const Offset(0.50, 0.78), const Offset(0.30, 0.76),
    const Offset(0.20, 0.64),
  ]),
  _s([const Offset(0.66, 0.32), const Offset(0.76, 0.24), const Offset(0.78, 0.38)]),
];

final List<List<Offset>> _pathJa = [
  _s([
    const Offset(0.34, 0.22), const Offset(0.50, 0.22), const Offset(0.64, 0.30),
    const Offset(0.68, 0.48), const Offset(0.60, 0.64), const Offset(0.44, 0.74),
    const Offset(0.28, 0.68), const Offset(0.26, 0.52),
  ]),
];

final List<List<Offset>> _pathJha = [
  _s([
    const Offset(0.30, 0.22), const Offset(0.46, 0.22), const Offset(0.60, 0.30),
    const Offset(0.64, 0.48), const Offset(0.56, 0.64), const Offset(0.40, 0.74),
    const Offset(0.24, 0.68), const Offset(0.22, 0.52),
  ]),
  _s([const Offset(0.64, 0.30), const Offset(0.74, 0.22), const Offset(0.76, 0.36)]),
];

final List<List<Offset>> _pathNya = [
  _s([
    const Offset(0.62, 0.28), const Offset(0.46, 0.20), const Offset(0.30, 0.28),
    const Offset(0.24, 0.44), const Offset(0.30, 0.58), const Offset(0.46, 0.64),
    const Offset(0.62, 0.58), const Offset(0.68, 0.44), const Offset(0.62, 0.30),
  ]),
  _s([const Offset(0.46, 0.64), const Offset(0.46, 0.80)]),
];

final List<List<Offset>> _pathTa = [
  _s([
    const Offset(0.26, 0.42), const Offset(0.30, 0.26), const Offset(0.50, 0.22),
    const Offset(0.70, 0.26), const Offset(0.72, 0.44), const Offset(0.60, 0.58),
    const Offset(0.44, 0.62), const Offset(0.34, 0.56), const Offset(0.26, 0.42),
  ]),
  _s([const Offset(0.44, 0.62), const Offset(0.44, 0.80)]),
];

final List<List<Offset>> _pathTha = [
  _s([
    const Offset(0.24, 0.44), const Offset(0.28, 0.26), const Offset(0.48, 0.20),
    const Offset(0.68, 0.26), const Offset(0.72, 0.46), const Offset(0.60, 0.60),
    const Offset(0.42, 0.64), const Offset(0.28, 0.58), const Offset(0.22, 0.44),
  ]),
  _s([const Offset(0.42, 0.64), const Offset(0.42, 0.82)]),
  _s([const Offset(0.58, 0.64), const Offset(0.70, 0.72), const Offset(0.64, 0.82)]),
];

final List<List<Offset>> _pathDa = [
  _s([
    const Offset(0.32, 0.22), const Offset(0.50, 0.18), const Offset(0.68, 0.28),
    const Offset(0.72, 0.48), const Offset(0.62, 0.68), const Offset(0.44, 0.76),
    const Offset(0.28, 0.66), const Offset(0.26, 0.46), const Offset(0.36, 0.32),
    const Offset(0.52, 0.28),
  ]),
];

final List<List<Offset>> _pathDha = [
  _s([
    const Offset(0.30, 0.22), const Offset(0.48, 0.18), const Offset(0.66, 0.28),
    const Offset(0.70, 0.48), const Offset(0.60, 0.68), const Offset(0.42, 0.76),
    const Offset(0.26, 0.66), const Offset(0.24, 0.46), const Offset(0.34, 0.32),
    const Offset(0.50, 0.28),
  ]),
  _s([const Offset(0.72, 0.34), const Offset(0.80, 0.26), const Offset(0.82, 0.42)]),
];

final List<List<Offset>> _pathNa = [
  _s([
    const Offset(0.62, 0.26), const Offset(0.46, 0.20), const Offset(0.32, 0.30),
    const Offset(0.28, 0.48), const Offset(0.38, 0.62), const Offset(0.54, 0.66),
    const Offset(0.66, 0.58), const Offset(0.68, 0.42),
  ]),
  _s([const Offset(0.50, 0.66), const Offset(0.50, 0.82)]),
];

final List<List<Offset>> _pathTa2 = [
  _s([
    const Offset(0.24, 0.38), const Offset(0.36, 0.22), const Offset(0.54, 0.20),
    const Offset(0.68, 0.30), const Offset(0.70, 0.48), const Offset(0.62, 0.64),
    const Offset(0.46, 0.72), const Offset(0.30, 0.64), const Offset(0.24, 0.48),
  ]),
];

final List<List<Offset>> _pathTha2 = [
  _s([
    const Offset(0.26, 0.40), const Offset(0.36, 0.22), const Offset(0.54, 0.20),
    const Offset(0.66, 0.30), const Offset(0.68, 0.50), const Offset(0.58, 0.66),
    const Offset(0.42, 0.74), const Offset(0.26, 0.64), const Offset(0.22, 0.48),
  ]),
  _s([const Offset(0.68, 0.36), const Offset(0.78, 0.28), const Offset(0.80, 0.44)]),
];

final List<List<Offset>> _pathDa2 = [
  _s([
    const Offset(0.26, 0.40), const Offset(0.30, 0.24), const Offset(0.50, 0.18),
    const Offset(0.68, 0.28), const Offset(0.72, 0.48), const Offset(0.60, 0.66),
    const Offset(0.42, 0.74), const Offset(0.26, 0.62), const Offset(0.24, 0.44),
  ]),
];

final List<List<Offset>> _pathDha2 = [
  _s([
    const Offset(0.24, 0.40), const Offset(0.28, 0.24), const Offset(0.48, 0.18),
    const Offset(0.66, 0.28), const Offset(0.70, 0.48), const Offset(0.58, 0.66),
    const Offset(0.40, 0.74), const Offset(0.24, 0.62), const Offset(0.22, 0.44),
  ]),
  _s([const Offset(0.70, 0.36), const Offset(0.78, 0.28), const Offset(0.80, 0.44)]),
];

final List<List<Offset>> _pathNa2 = [
  _s([
    const Offset(0.28, 0.30), const Offset(0.28, 0.70),
  ]),
  _s([
    const Offset(0.28, 0.30), const Offset(0.50, 0.22), const Offset(0.68, 0.30),
    const Offset(0.70, 0.50), const Offset(0.56, 0.66), const Offset(0.38, 0.66),
    const Offset(0.28, 0.56),
  ]),
];

final List<List<Offset>> _pathPa = [
  _s([
    const Offset(0.34, 0.22), const Offset(0.34, 0.78),
  ]),
  _s([
    const Offset(0.34, 0.22), const Offset(0.54, 0.22), const Offset(0.68, 0.32),
    const Offset(0.68, 0.48), const Offset(0.54, 0.56), const Offset(0.34, 0.56),
  ]),
];

final List<List<Offset>> _pathPha = [
  _s([const Offset(0.32, 0.22), const Offset(0.32, 0.80)]),
  _s([
    const Offset(0.32, 0.22), const Offset(0.52, 0.22), const Offset(0.66, 0.32),
    const Offset(0.66, 0.48), const Offset(0.52, 0.58), const Offset(0.32, 0.58),
  ]),
  _s([const Offset(0.66, 0.38), const Offset(0.76, 0.30), const Offset(0.78, 0.44)]),
];

final List<List<Offset>> _pathBa = [
  _s([const Offset(0.34, 0.22), const Offset(0.34, 0.80)]),
  _s([
    const Offset(0.34, 0.22), const Offset(0.54, 0.22), const Offset(0.66, 0.30),
    const Offset(0.66, 0.44), const Offset(0.52, 0.52), const Offset(0.34, 0.52),
  ]),
  _s([
    const Offset(0.34, 0.52), const Offset(0.54, 0.52), const Offset(0.68, 0.62),
    const Offset(0.68, 0.72), const Offset(0.54, 0.80), const Offset(0.34, 0.80),
  ]),
];

final List<List<Offset>> _pathBha = [
  _s([const Offset(0.32, 0.22), const Offset(0.32, 0.80)]),
  _s([
    const Offset(0.32, 0.22), const Offset(0.52, 0.22), const Offset(0.64, 0.30),
    const Offset(0.64, 0.44), const Offset(0.50, 0.52), const Offset(0.32, 0.52),
  ]),
  _s([
    const Offset(0.32, 0.52), const Offset(0.52, 0.52), const Offset(0.66, 0.62),
    const Offset(0.66, 0.72), const Offset(0.52, 0.80), const Offset(0.32, 0.80),
  ]),
  _s([const Offset(0.66, 0.30), const Offset(0.76, 0.22), const Offset(0.78, 0.36)]),
];

final List<List<Offset>> _pathMa = [
  _s([
    const Offset(0.22, 0.28), const Offset(0.22, 0.76),
  ]),
  _s([
    const Offset(0.22, 0.28), const Offset(0.36, 0.20), const Offset(0.50, 0.28),
    const Offset(0.50, 0.52),
  ]),
  _s([
    const Offset(0.50, 0.28), const Offset(0.64, 0.20), const Offset(0.76, 0.28),
    const Offset(0.76, 0.76),
  ]),
];

final List<List<Offset>> _pathYa = [
  _s([
    const Offset(0.26, 0.22), const Offset(0.50, 0.50), const Offset(0.50, 0.78),
  ]),
  _s([
    const Offset(0.74, 0.22), const Offset(0.50, 0.50),
  ]),
];

final List<List<Offset>> _pathRa = [
  _s([
    const Offset(0.62, 0.24), const Offset(0.48, 0.18), const Offset(0.32, 0.26),
    const Offset(0.26, 0.44), const Offset(0.32, 0.58), const Offset(0.50, 0.64),
    const Offset(0.64, 0.56), const Offset(0.68, 0.40), const Offset(0.58, 0.28),
    const Offset(0.44, 0.26), const Offset(0.32, 0.32),
  ]),
];

final List<List<Offset>> _pathLa = [
  _s([
    const Offset(0.34, 0.22), const Offset(0.34, 0.68), const Offset(0.44, 0.78),
    const Offset(0.58, 0.78), const Offset(0.68, 0.70),
  ]),
];

final List<List<Offset>> _pathVa = [
  _s([
    const Offset(0.26, 0.30), const Offset(0.28, 0.56), const Offset(0.40, 0.72),
    const Offset(0.56, 0.76), const Offset(0.68, 0.68), const Offset(0.70, 0.50),
    const Offset(0.60, 0.38), const Offset(0.44, 0.32), const Offset(0.30, 0.36),
  ]),
];

final List<List<Offset>> _pathSha = [
  _s([
    const Offset(0.64, 0.26), const Offset(0.48, 0.20), const Offset(0.32, 0.28),
    const Offset(0.28, 0.44), const Offset(0.40, 0.52), const Offset(0.58, 0.50),
    const Offset(0.68, 0.60), const Offset(0.58, 0.74), const Offset(0.40, 0.76),
    const Offset(0.26, 0.66),
  ]),
];

final List<List<Offset>> _pathSsa = [
  _s([
    const Offset(0.66, 0.28), const Offset(0.50, 0.20), const Offset(0.34, 0.28),
    const Offset(0.28, 0.44), const Offset(0.36, 0.54), const Offset(0.54, 0.54),
    const Offset(0.64, 0.64), const Offset(0.54, 0.76), const Offset(0.36, 0.76),
    const Offset(0.26, 0.66),
  ]),
  _s([const Offset(0.36, 0.54), const Offset(0.36, 0.80)]),
];

final List<List<Offset>> _pathSa = [
  _s([
    const Offset(0.68, 0.28), const Offset(0.52, 0.20), const Offset(0.36, 0.28),
    const Offset(0.28, 0.42), const Offset(0.36, 0.52), const Offset(0.56, 0.52),
    const Offset(0.68, 0.62), const Offset(0.56, 0.76), const Offset(0.36, 0.76),
    const Offset(0.24, 0.64),
  ]),
];

final List<List<Offset>> _pathHa = [
  _s([const Offset(0.30, 0.22), const Offset(0.30, 0.78)]),
  _s([const Offset(0.68, 0.22), const Offset(0.68, 0.78)]),
  _s([const Offset(0.30, 0.50), const Offset(0.68, 0.50)]),
];

final List<List<Offset>> _pathLla = [
  _s([
    const Offset(0.34, 0.22), const Offset(0.34, 0.70), const Offset(0.44, 0.80),
    const Offset(0.60, 0.80), const Offset(0.70, 0.70), const Offset(0.70, 0.54),
    const Offset(0.58, 0.46), const Offset(0.34, 0.46),
  ]),
];

final List<List<Offset>> _pathKsha = [
  _s([
    const Offset(0.42, 0.22), const Offset(0.30, 0.22), const Offset(0.22, 0.34),
    const Offset(0.22, 0.50), const Offset(0.30, 0.62), const Offset(0.42, 0.66),
    const Offset(0.42, 0.80),
  ]),
  _s([
    const Offset(0.56, 0.22), const Offset(0.68, 0.22), const Offset(0.76, 0.34),
    const Offset(0.76, 0.50), const Offset(0.68, 0.62), const Offset(0.56, 0.66),
    const Offset(0.56, 0.80),
  ]),
  _s([const Offset(0.42, 0.44), const Offset(0.56, 0.44)]),
];

final List<List<Offset>> _pathGya = [
  _s([
    const Offset(0.30, 0.22), const Offset(0.30, 0.78),
  ]),
  _s([
    const Offset(0.30, 0.22), const Offset(0.50, 0.22), const Offset(0.66, 0.32),
    const Offset(0.68, 0.50), const Offset(0.56, 0.64), const Offset(0.38, 0.68),
    const Offset(0.28, 0.60),
  ]),
  _s([
    const Offset(0.52, 0.68), const Offset(0.66, 0.72), const Offset(0.68, 0.84),
    const Offset(0.56, 0.88),
  ]),
];

// ─── Public path map ─────────────────────────────────────────────────────────

/// Returns the list of strokes (each stroke = dense list of Offsets in [0,1])
/// for the given Odia letter character.
/// Falls back to a simple circle for unrecognised characters.
List<List<Offset>> getTracePaths(String character) {
  return _paths[character] ?? _fallbackPath;
}

final List<List<Offset>> _fallbackPath = [
  _s([
    const Offset(0.50, 0.22), const Offset(0.68, 0.28), const Offset(0.76, 0.48),
    const Offset(0.68, 0.68), const Offset(0.50, 0.76), const Offset(0.32, 0.68),
    const Offset(0.24, 0.48), const Offset(0.32, 0.28), const Offset(0.50, 0.22),
  ]),
];

final Map<String, List<List<Offset>>> _paths = {
  // Vowels
  'ଅ': _pathA,
  'ଆ': _pathAa,
  'ଇ': _pathI,
  'ଈ': _pathIi,
  'ଉ': _pathU,
  'ଊ': _pathUu,
  'ଋ': _pathRu,
  'ଏ': _pathE,
  'ଐ': _pathAi,
  'ଓ': _pathO,
  'ଔ': _pathAu,
  'ଅଂ': _pathA, // anusvara — reuse base vowel path
  'ଅଃ': _pathA, // visarga  — reuse base vowel path
  // Consonants
  'କ': _pathKa,
  'ଖ': _pathKha,
  'ଗ': _pathGa,
  'ଘ': _pathGha,
  'ଙ': _pathNga,
  'ଚ': _pathCha,
  'ଛ': _pathChha,
  'ଜ': _pathJa,
  'ଝ': _pathJha,
  'ଞ': _pathNya,
  'ଟ': _pathTa,
  'ଠ': _pathTha,
  'ଡ': _pathDa,
  'ଢ': _pathDha,
  'ଣ': _pathNa,
  'ତ': _pathTa2,
  'ଥ': _pathTha2,
  'ଦ': _pathDa2,
  'ଧ': _pathDha2,
  'ନ': _pathNa2,
  'ପ': _pathPa,
  'ଫ': _pathPha,
  'ବ': _pathBa,
  'ଭ': _pathBha,
  'ମ': _pathMa,
  'ଯ': _pathYa,
  'ର': _pathRa,
  'ଲ': _pathLa,
  'ଵ': _pathVa,
  'ଶ': _pathSha,
  'ଷ': _pathSsa,
  'ସ': _pathSa,
  'ହ': _pathHa,
  'ଳ': _pathLla,
  'କ୍ଷ': _pathKsha,
  'ଜ୍ଞ': _pathGya,
};
