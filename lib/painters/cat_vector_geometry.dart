// lib/painters/cat_vector_geometry.dart
// Exact mathematical geometry, Catmull-Rom splines, poses, and gait models
// from the official FocusCat web rig (cat-shapes.js).

import 'dart:math' as math;
import 'package:flutter/material.dart';

class CatVectorGeometry {
  static const double designWidth = 200.0;
  static const double designHeight = 150.0;
  static const double floorY = 137.0;

  static const double rad = math.pi / 180.0;

  // ---------------------------------------------------------------------------
  // Catmull-Rom to Cubic Bezier Path Builder
  // ---------------------------------------------------------------------------
  static Path buildSplinePath(List<List<double>> points, bool closed) {
    final path = Path();
    final n = points.length;
    if (n < 2) return path;

    List<double> at(int i) {
      if (closed) {
        return points[(i % n + n) % n];
      }
      return points[i.clamp(0, n - 1)];
    }

    double ten(List<double> p) => p.length > 2 ? p[2] : 1.0;

    path.moveTo(points[0][0], points[0][1]);
    final segs = closed ? n : n - 1;

    for (int i = 0; i < segs; i++) {
      final p0 = at(i - 1);
      final p1 = at(i);
      final p2 = at(i + 1);
      final p3 = at(i + 2);

      final k1 = ten(p1) / 6.0;
      final k2 = ten(p2) / 6.0;

      final cp1x = p1[0] + (p2[0] - p0[0]) * k1;
      final cp1y = p1[1] + (p2[1] - p0[1]) * k1;
      final cp2x = p2[0] - (p3[0] - p1[0]) * k2;
      final cp2y = p2[1] - (p3[1] - p1[1]) * k2;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2[0], p2[1]);
    }

    if (closed) {
      path.close();
    }
    return path;
  }

  // ---------------------------------------------------------------------------
  // Point transformations
  // ---------------------------------------------------------------------------
  static List<List<double>> rotatePts(
      List<List<double>> pts, double deg, double cx, double cy) {
    final a = deg * rad;
    final cosA = math.cos(a);
    final sinA = math.sin(a);
    return pts.map((p) {
      final dx = p[0] - cx;
      final dy = p[1] - cy;
      return [
        cx + dx * cosA - dy * sinA,
        cy + dx * sinA + dy * cosA,
        p.length > 2 ? p[2] : 1.0
      ];
    }).toList();
  }

  static List<List<double>> swayTail(List<List<double>> pts, double deg) {
    final ox = pts[0][0];
    final oy = pts[0][1];
    final len = pts.length;
    return List.generate(len, (i) {
      final w = i / (len - 1);
      final a = deg * w * w * rad;
      final dx = pts[i][0] - ox;
      final dy = pts[i][1] - oy;
      return [
        ox + dx * math.cos(a) - dy * math.sin(a),
        oy + dx * math.sin(a) + dy * math.cos(a)
      ];
    });
  }

  static List<List<double>> tailWave(
      List<List<double>> pts, double phase, double amp, double lag) {
    final ox = pts[0][0];
    final oy = pts[0][1];
    final len = pts.length;
    return List.generate(len, (i) {
      final w = i / (len - 1);
      final a =
          amp * w * w * math.sin(2 * math.pi * (phase - lag * w)) * rad;
      final dx = pts[i][0] - ox;
      final dy = pts[i][1] - oy;
      return [
        ox + dx * math.cos(a) - dy * math.sin(a),
        oy + dx * math.sin(a) + dy * math.cos(a)
      ];
    });
  }

  static List<List<double>> flickEars(List<List<double>> headPts) {
    final out = headPts.map((p) => List<double>.from(p)).toList();
    out[2][0] += 2.5;
    out[2][1] -= 3.5;
    out[0][1] += 1.2;
    return out;
  }

  static List<List<double>> flattenEars(List<List<double>> headPts, double amt) {
    final out = headPts.map((p) => List<double>.from(p)).toList();
    out[0][1] += amt;
    out[0][0] -= amt * 0.5;
    out[2][1] += amt;
    out[2][0] += amt * 0.5;
    out[1][1] += amt * 0.25;
    return out;
  }

  // ---------------------------------------------------------------------------
  // Eyes (6-point rings)
  // ---------------------------------------------------------------------------
  static List<List<double>> ring(
      double cx, double cy, double rx, double ry, [int n = 6]) {
    final pts = <List<double>>[];
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2.0 + (i * 2.0 * math.pi) / n;
      pts.add([cx + rx * math.cos(a), cy + ry * math.sin(a), 1.0]);
    }
    return pts;
  }

  static List<List<double>> bowEnds(List<List<double>> pts, double amount) {
    final out = pts.map((p) => List<double>.from(p)).toList();
    for (final idx in [1, 2, 4, 5]) {
      out[idx][1] += amount;
    }
    return out;
  }

  static List<List<double>> eyeOpen(double cx, double cy) =>
      ring(cx, cy, 5.45, 6.5);
  static List<List<double>> eyeClosed(double cx, double cy) =>
      bowEnds(ring(cx, cy + 1.3, 7.1, 1.25), 2.4);
  static List<List<double>> eyeHappy(double cx, double cy) =>
      bowEnds(ring(cx, cy + 2.1, 7.5, 1.25), 4.4);
  static List<List<double>> eyeAngry(double cx, double cy, double inward) =>
      rotatePts(ring(cx, cy + 0.4, 5.8, 3.25), 19 * inward, cx, cy);
  static List<List<double>> eyeBored(double cx, double cy) {
    final p = ring(cx, cy + 1.6, 5.2, 3.5);
    p[0][1] += 1.7;
    p[1][1] += 0.8;
    p[5][1] += 0.8;
    return p;
  }

  // ---------------------------------------------------------------------------
  // Mouths (5-point open strokes)
  // ---------------------------------------------------------------------------
  static const Map<String, List<List<double>>> mouths = {
    'smile': [
      [-4.2, 10.6],
      [-2.1, 12.9],
      [0.0, 11.0],
      [2.1, 12.9],
      [4.2, 10.6]
    ],
    'grin': [
      [-6.5, 9.4],
      [-3.0, 14.4],
      [0.0, 10.4],
      [3.0, 14.4],
      [6.5, 9.4]
    ],
    'soft': [
      [-4.0, 11.4],
      [-2.0, 12.4],
      [0.0, 12.7],
      [2.0, 12.4],
      [4.0, 11.4]
    ],
    'frown': [
      [-5.5, 13.6],
      [-2.6, 9.9],
      [0.0, 9.3],
      [2.6, 9.9],
      [5.5, 13.6]
    ],
    'snarl': [
      [-6.5, 14.6],
      [-3.0, 9.6],
      [0.0, 8.8],
      [3.0, 9.6],
      [6.5, 14.6]
    ],
    'flat': [
      [-5.0, 11.6],
      [-2.5, 11.9],
      [0.0, 12.0],
      [2.5, 11.9],
      [5.0, 11.6]
    ],
    'oh': [
      [-3.2, 10.2],
      [-1.8, 13.8],
      [0.0, 14.4],
      [1.8, 13.8],
      [3.2, 10.2]
    ],
    'yawn': [
      [-3.6, 9.4],
      [-2.0, 16.0],
      [0.0, 16.8],
      [2.0, 16.0],
      [3.6, 9.4]
    ],
  };

  // ---------------------------------------------------------------------------
  // Head silhouettes
  // ---------------------------------------------------------------------------
  static const List<List<double>> headAwake = [
    [-20.0, -38.0, 0.34],
    [-2.0, -19.0, 0.85],
    [17.0, -38.0, 0.34],
    [29.0, -13.0, 0.80],
    [32.0, 5.0, 1.00],
    [22.0, 22.0, 1.00],
    [0.0, 28.0, 1.00],
    [-21.0, 22.0, 1.00],
    [-32.0, 5.0, 1.00],
    [-31.0, -13.0, 0.80]
  ];

  static const List<List<double>> headSleep = [
    [-24.0, -30.0, 0.34],
    [-2.0, -16.0, 0.85],
    [12.0, -31.0, 0.34],
    [28.0, -11.0, 0.80],
    [33.0, 6.0, 1.00],
    [23.0, 22.0, 1.00],
    [0.0, 28.0, 1.00],
    [-21.0, 22.0, 1.00],
    [-33.0, 6.0, 1.00],
    [-32.0, -11.0, 0.80]
  ];

  static const List<List<double>> headAngry = [
    [-30.0, -22.0, 0.20],
    [-2.0, -22.0, 0.85],
    [24.0, -24.0, 0.20],
    [30.0, -12.0, 0.80],
    [32.0, 5.0, 1.00],
    [22.0, 22.0, 1.00],
    [0.0, 28.0, 1.00],
    [-21.0, 22.0, 1.00],
    [-32.0, 5.0, 1.00],
    [-32.0, -12.0, 0.80]
  ];

  static const List<List<double>> headBored = [
    [-22.0, -33.0, 0.32],
    [-2.0, -17.0, 0.85],
    [15.0, -34.0, 0.32],
    [29.0, -12.0, 0.80],
    [32.0, 5.0, 1.00],
    [22.0, 22.0, 1.00],
    [0.0, 28.0, 1.00],
    [-21.0, 22.0, 1.00],
    [-32.0, 5.0, 1.00],
    [-31.0, -12.0, 0.80]
  ];

  // Inner ears
  static const List<List<double>> earLAwake = [
    [-19.5, -33.0, 0.34],
    [-7.5, -20.5, 0.90],
    [-26.0, -17.0, 0.80]
  ];
  static const List<List<double>> earRAwake = [
    [16.2, -33.0, 0.34],
    [24.0, -16.6, 0.80],
    [3.9, -20.5, 0.90]
  ];

  static const List<List<double>> earLSleep = [
    [-22.4, -26.0, 0.34],
    [-8.0, -17.0, 0.90],
    [-27.6, -14.0, 0.80]
  ];
  static const List<List<double>> earRSleep = [
    [12.2, -27.0, 0.34],
    [22.6, -14.0, 0.80],
    [3.1, -17.0, 0.90]
  ];

  static const List<List<double>> earLAngry = [
    [-27.0, -20.8, 0.34],
    [-8.8, -20.8, 0.90],
    [-28.2, -14.3, 0.80]
  ];
  static const List<List<double>> earRAngry = [
    [21.7, -22.4, 0.34],
    [25.6, -14.6, 0.80],
    [4.8, -21.1, 0.90]
  ];

  static const List<List<double>> earLBored = [
    [-20.8, -28.8, 0.34],
    [-7.8, -19.0, 0.90],
    [-26.2, -16.0, 0.80]
  ];
  static const List<List<double>> earRBored = [
    [14.8, -29.4, 0.34],
    [24.2, -15.6, 0.80],
    [4.0, -19.0, 0.90]
  ];

  // ---------------------------------------------------------------------------
  // Gait Model for Walk and Angry Cycles
  // ---------------------------------------------------------------------------
  static const double stance = 0.62;

  static List<List<double>> legFrame(
    List<double> hip,
    double reach,
    double len,
    double lift,
    double bend,
    double phase,
  ) {
    final ph = ((phase % 1.0) + 1.0) % 1.0;
    final hx = hip[0];
    final hy = hip[1];
    double px, py;

    if (ph < stance) {
      final t = ph / stance;
      px = reach * (1.0 - 2.0 * t);
      py = len;
    } else {
      final t = (ph - stance) / (1.0 - stance);
      final s = t * t * (3.0 - 2.0 * t);
      px = -reach + 2.0 * reach * s;
      py = len - lift * math.sin(math.pi * t);
    }

    final straight = 1.0 - math.min(1.0, px.abs() / (reach > 0 ? reach : 1.0));
    final b = bend * (0.55 + 0.75 * straight);

    return [
      [hx, hy],
      [hx + px * 0.45 + b, hy + py * 0.5],
      [hx + px, hy + py]
    ];
  }

  // ---------------------------------------------------------------------------
  // Poses Definition
  // ---------------------------------------------------------------------------
  static const Map<String, List<List<double>>> bodyWalk = {
    'body': [
      [136.0, 68.0, 1.0],
      [112.0, 59.0, 1.0],
      [84.0, 59.0, 1.0],
      [60.0, 70.0, 1.0],
      [46.0, 90.0, 1.0],
      [56.0, 111.0, 1.0],
      [86.0, 117.0, 1.0],
      [114.0, 115.0, 1.0],
      [136.0, 105.0, 1.0],
      [144.0, 84.0, 1.0]
    ],
    'tail': [
      [58.0, 98.0],
      [42.0, 92.0],
      [31.0, 79.0],
      [32.0, 63.0],
      [42.0, 56.0]
    ]
  };

  static const Map<String, List<List<double>>> bodySit = {
    'body': [
      [124.0, 62.0, 1.0],
      [110.0, 55.0, 1.0],
      [95.0, 64.0, 1.0],
      [82.0, 88.0, 1.0],
      [76.0, 112.0, 1.0],
      [82.0, 130.0, 1.0],
      [108.0, 136.0, 1.0],
      [132.0, 135.0, 1.0],
      [145.0, 113.0, 1.0],
      [141.0, 84.0, 1.0]
    ],
    'tail': [
      [86.0, 124.0],
      [64.0, 128.0],
      [48.0, 132.0],
      [36.0, 130.0],
      [30.0, 121.0]
    ],
    'fn': [
      [130.0, 120.0],
      [138.0, 127.0],
      [148.0, 130.0]
    ],
    'ff': [
      [122.0, 122.0],
      [130.0, 128.0],
      [140.0, 131.0]
    ],
    'bn': [
      [95.0, 119.0],
      [99.0, 122.0],
      [103.0, 124.0]
    ],
    'bf': [
      [89.0, 120.0],
      [93.0, 123.0],
      [97.0, 125.0]
    ]
  };

  static const Map<String, List<List<double>>> bodySleep = {
    'body': [
      [134.0, 98.0, 1.0],
      [110.0, 90.0, 1.0],
      [84.0, 88.0, 1.0],
      [60.0, 96.0, 1.0],
      [48.0, 110.0, 1.0],
      [54.0, 126.0, 1.0],
      [84.0, 134.0, 1.0],
      [112.0, 134.0, 1.0],
      [136.0, 128.0, 1.0],
      [144.0, 112.0, 1.0]
    ],
    'tail': [
      [60.0, 114.0],
      [44.0, 121.0],
      [37.0, 130.0],
      [50.0, 135.0],
      [76.0, 134.0]
    ],
    'fn': [
      [119.0, 121.0],
      [126.0, 126.0],
      [135.0, 128.0]
    ],
    'ff': [
      [110.0, 120.0],
      [116.0, 123.0],
      [122.0, 124.0]
    ],
    'bn': [
      [76.0, 119.0],
      [82.0, 122.0],
      [88.0, 123.0]
    ],
    'bf': [
      [70.0, 119.0],
      [76.0, 122.0],
      [82.0, 123.0]
    ]
  };

  static const Map<String, List<List<double>>> bodyPat = {
    'body': [
      [124.0, 66.0, 1.0],
      [110.0, 60.0, 1.0],
      [93.0, 69.0, 1.0],
      [80.0, 92.0, 1.0],
      [74.0, 115.0, 1.0],
      [81.0, 131.0, 1.0],
      [108.0, 137.0, 1.0],
      [133.0, 136.0, 1.0],
      [147.0, 115.0, 1.0],
      [142.0, 88.0, 1.0]
    ],
    'tail': [
      [86.0, 124.0],
      [66.0, 124.0],
      [52.0, 116.0],
      [48.0, 102.0],
      [54.0, 94.0]
    ],
    'fn': [
      [130.0, 122.0],
      [138.0, 128.0],
      [148.0, 131.0]
    ],
    'ff': [
      [122.0, 124.0],
      [130.0, 129.0],
      [140.0, 132.0]
    ],
    'bn': [
      [95.0, 120.0],
      [99.0, 123.0],
      [103.0, 125.0]
    ],
    'bf': [
      [89.0, 121.0],
      [93.0, 124.0],
      [97.0, 126.0]
    ]
  };

  static const Map<String, List<List<double>>> bodyGreet = {
    'body': [
      [124.0, 60.0, 1.0],
      [110.0, 53.0, 1.0],
      [95.0, 62.0, 1.0],
      [82.0, 86.0, 1.0],
      [76.0, 110.0, 1.0],
      [82.0, 129.0, 1.0],
      [108.0, 136.0, 1.0],
      [132.0, 135.0, 1.0],
      [145.0, 112.0, 1.0],
      [141.0, 82.0, 1.0]
    ],
    'tail': [
      [86.0, 124.0],
      [66.0, 123.0],
      [52.0, 114.0],
      [48.0, 100.0],
      [55.0, 92.0]
    ],
    'fnWaveOut': [
      [128.0, 116.0],
      [143.0, 105.0],
      [159.0, 93.0]
    ],
    'fnWaveBack': [
      [128.0, 116.0],
      [137.0, 113.0],
      [146.0, 107.0]
    ],
    'fn': [
      [128.0, 116.0],
      [142.0, 107.0],
      [156.0, 96.0]
    ],
    'ff': [
      [122.0, 122.0],
      [130.0, 128.0],
      [140.0, 131.0]
    ],
    'bn': [
      [95.0, 119.0],
      [99.0, 122.0],
      [103.0, 124.0]
    ],
    'bf': [
      [89.0, 120.0],
      [93.0, 123.0],
      [97.0, 125.0]
    ]
  };

  static const Map<String, List<List<double>>> bodyBored = {
    'body': [
      [128.0, 88.0, 1.0],
      [106.0, 80.0, 1.0],
      [82.0, 80.0, 1.0],
      [60.0, 88.0, 1.0],
      [50.0, 104.0, 1.0],
      [56.0, 122.0, 1.0],
      [86.0, 130.0, 1.0],
      [112.0, 130.0, 1.0],
      [134.0, 124.0, 1.0],
      [142.0, 106.0, 1.0]
    ],
    'tail': [
      [58.0, 114.0],
      [42.0, 121.0],
      [26.0, 127.0],
      [14.0, 131.0],
      [6.0, 129.0]
    ],
    'fn': [
      [122.0, 116.0],
      [132.0, 124.0],
      [146.0, 128.0]
    ],
    'ff': [
      [114.0, 118.0],
      [124.0, 126.0],
      [138.0, 130.0]
    ],
    'bn': [
      [76.0, 116.0],
      [82.0, 121.0],
      [88.0, 123.0]
    ],
    'bf': [
      [70.0, 117.0],
      [76.0, 122.0],
      [82.0, 124.0]
    ]
  };

  static const Map<String, List<List<double>>> bodyAngry = {
    'body': [
      [136.0, 72.0, 1.0],
      [112.0, 63.0, 1.0],
      [84.0, 62.0, 1.0],
      [60.0, 72.0, 1.0],
      [46.0, 91.0, 1.0],
      [56.0, 112.0, 1.0],
      [86.0, 118.0, 1.0],
      [114.0, 116.0, 1.0],
      [136.0, 107.0, 1.0],
      [144.0, 87.0, 1.0]
    ],
    'tail': [
      [58.0, 100.0],
      [43.0, 97.0],
      [29.0, 95.0],
      [17.0, 94.0],
      [7.0, 95.0]
    ]
  };

  static const Map<String, List<List<double>>> bodyConfront = {
    'body': [
      [136.0, 76.0, 1.0],
      [112.0, 66.0, 1.0],
      [84.0, 65.0, 1.0],
      [60.0, 75.0, 1.0],
      [46.0, 93.0, 1.0],
      [56.0, 113.0, 1.0],
      [86.0, 119.0, 1.0],
      [114.0, 117.0, 1.0],
      [136.0, 109.0, 1.0],
      [144.0, 90.0, 1.0]
    ],
    'tail': [
      [58.0, 112.0],
      [42.0, 116.0],
      [28.0, 122.0],
      [16.0, 126.0],
      [8.0, 124.0]
    ],
    'fn': [
      [126.0, 96.0],
      [130.0, 110.0],
      [133.0, 124.0]
    ],
    'ff': [
      [116.0, 97.0],
      [119.0, 111.0],
      [122.0, 125.0]
    ],
    'bn': [
      [72.0, 94.0],
      [78.0, 110.0],
      [82.0, 127.0]
    ],
    'bf': [
      [62.0, 95.0],
      [68.0, 111.0],
      [72.0, 128.0]
    ]
  };

  // Swat Strike Paw Stages (hip -> knee -> paw)
  static const List<List<double>> swatCock = [
    [126.0, 90.0],
    [112.0, 82.0],
    [100.0, 72.0]
  ];
  static const List<List<double>> swatStrike = [
    [128.0, 98.0],
    [155.0, 108.0],
    [182.0, 126.0]
  ];
  static const List<List<double>> swatTrail = [
    [132.0, 108.0],
    [140.0, 118.0],
    [148.0, 127.0]
  ];
}
