// lib/painters/pixel_cat_painter.dart
// FocusCat painter delegating to the official FocusCat vector renderer.

import 'package:flutter/material.dart';

import '../models/cat_models.dart';
import 'focus_cat_vector_painter.dart';

class PixelCatPainter extends CustomPainter {
  final CatPose pose;
  final CatColorPalette palette;
  final bool facingRight;
  final int frameIndex;
  final bool showKeyboard;
  final double animationTime;
  final bool isSwatting;
  final double swatProgress;

  PixelCatPainter({
    required this.pose,
    required this.palette,
    required this.facingRight,
    this.frameIndex = 0,
    this.showKeyboard = false,
    double? animationTime,
    this.isSwatting = false,
    this.swatProgress = 0.0,
  }) : animationTime = animationTime ?? (frameIndex * 0.28);

  @override
  void paint(Canvas canvas, Size size) {
    final vectorPainter = FocusCatVectorPainter(
      pose: pose,
      palette: palette,
      facingRight: facingRight,
      animationTime: animationTime,
      isSwatting: isSwatting,
      swatProgress: swatProgress,
    );
    vectorPainter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant PixelCatPainter oldDelegate) {
    return true;
  }
}
