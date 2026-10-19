// lib/painters/focus_cat_vector_painter.dart
// 60fps Vector Cat Painter replicating the official FocusCat web rig.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/cat_models.dart';
import 'cat_vector_geometry.dart';

class FocusCatVectorPainter extends CustomPainter {
  final CatPose pose;
  final CatColorPalette palette;
  final bool facingRight;
  final double animationTime; // elapsed seconds
  final bool isSwatting;
  final double swatProgress; // 0.0 to 1.0 during swat

  const FocusCatVectorPainter({
    required this.pose,
    required this.palette,
    required this.facingRight,
    required this.animationTime,
    this.isSwatting = false,
    this.swatProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Scale from 200x150 design space to target canvas size
    final scaleX = size.width / CatVectorGeometry.designWidth;
    final scaleY = size.height / CatVectorGeometry.designHeight;
    canvas.scale(scaleX, scaleY);

    // Mirror horizontally if facing left
    if (!facingRight) {
      canvas.translate(CatVectorGeometry.designWidth, 0);
      canvas.scale(-1, 1);
    }

    final t = animationTime;

    // -------------------------------------------------------------------------
    // Animation computations per pose
    // -------------------------------------------------------------------------
    double bodyScaleY = 1.0;
    double bodyScaleX = 1.0;
    double bodyY = 0.0;
    double bodyX = 0.0;
    double bodyRot = 0.0;

    double headBobY = 0.0;
    double headBobX = 0.0;
    double headBobRot = 0.0;

    String currentEyeState = 'open';
    bool showGlints = true;
    double glintOpacity = 1.0;

    // Blinking logic (every ~3.5 seconds)
    final blinkCycle = t % 3.5;
    bool isBlinking = false;
    if (blinkCycle < 0.16 && (pose == CatPose.sit || pose == CatPose.walk || pose == CatPose.greet)) {
      isBlinking = true;
      currentEyeState = 'closed';
      showGlints = false;
    }

    // Ear twitch logic (every ~6 seconds)
    final twitchCycle = t % 6.0;
    final bool isTwitching = twitchCycle < 0.22 && (pose == CatPose.sit || pose == CatPose.bored);

    List<List<double>> currentTail;
    double tailWidth = 9.0;

    // Gait parameters
    double walkPhase = (t * 1.6) % 1.0;
    if (pose == CatPose.angry) {
      walkPhase = (t * 2.8) % 1.0;
    }

    // Poses setup
    Offset headBasePos = const Offset(136, 57);
    double headBaseRot = -3.0;
    double headScale = 1.09;
    List<List<double>> headPts = CatVectorGeometry.headAwake;
    List<List<double>> earLPts = CatVectorGeometry.earLAwake;
    List<List<double>> earRPts = CatVectorGeometry.earRAwake;
    List<List<double>> bodyPts = CatVectorGeometry.bodySit['body']!;
    List<List<double>> mouthPts = CatVectorGeometry.mouths['smile']!;
    double shadowRx = 36.0;
    double shadowCx = 108.0;
    double shadowOpacity = 0.24;

    switch (pose) {
      case CatPose.sit:
        bodyPts = CatVectorGeometry.bodySit['body']!;
        headBasePos = const Offset(136, 57);
        headBaseRot = -3.0;
        headScale = 1.09;
        shadowRx = 36.0;
        shadowCx = 108.0;
        shadowOpacity = 0.24;
        currentEyeState = isBlinking ? 'closed' : 'open';
        mouthPts = CatVectorGeometry.mouths['smile']!;

        // Breathing cycle: 3.0s full period
        final breath = math.sin(t * 2 * math.pi / 3.0);
        bodyScaleY = 1.0 + 0.022 * breath;
        bodyScaleX = 1.0 - 0.006 * breath;
        bodyY = -0.8 * breath;
        headBobY = -1.6 * breath;

        // Lazy tail flick: rests then two subtle flicks
        final tailCycle = t % 3.2;
        double tailAngle = 0.0;
        if (tailCycle > 1.1 && tailCycle <= 1.55) {
          tailAngle = -13.0 * math.sin((tailCycle - 1.1) / 0.45 * math.pi);
        } else if (tailCycle > 1.55 && tailCycle <= 2.1) {
          tailAngle = 6.0 * math.sin((tailCycle - 1.55) / 0.55 * math.pi);
        } else if (tailCycle > 2.1 && tailCycle <= 2.6) {
          tailAngle = -9.0 * math.sin((tailCycle - 2.1) / 0.5 * math.pi);
        }
        currentTail = CatVectorGeometry.swayTail(
          CatVectorGeometry.bodySit['tail']!,
          tailAngle,
        );
        break;

      case CatPose.walk:
        bodyPts = CatVectorGeometry.bodyWalk['body']!;
        headBasePos = const Offset(152, 72);
        headBaseRot = 0.0;
        headScale = 1.03;
        shadowRx = 50.0;
        shadowCx = 94.0;
        shadowOpacity = 0.28;
        currentEyeState = isBlinking ? 'closed' : 'open';
        mouthPts = CatVectorGeometry.mouths['smile']!;

        // Two bobs per stride
        final strideBob = math.sin(walkPhase * 4 * math.pi);
        bodyY = -2.1 * strideBob.abs();
        headBobY = -2.6 * strideBob.abs();
        headBobRot = -1.5 * strideBob;

        // Travelling wave on tail
        currentTail = CatVectorGeometry.tailWave(
          CatVectorGeometry.bodyWalk['tail']!,
          walkPhase * 0.5,
          10.0,
          0.3,
        );
        break;

      case CatPose.sleep:
        bodyPts = CatVectorGeometry.bodySleep['body']!;
        headPts = CatVectorGeometry.headSleep;
        earLPts = CatVectorGeometry.earLSleep;
        earRPts = CatVectorGeometry.earRSleep;
        headBasePos = const Offset(142, 105);
        headBaseRot = 9.0;
        headScale = 1.08;
        shadowRx = 54.0;
        shadowCx = 96.0;
        shadowOpacity = 0.26;
        currentEyeState = 'closed';
        showGlints = false;
        mouthPts = CatVectorGeometry.mouths['soft']!;

        // Slow deep breathing
        final sleepBreath = math.sin(t * 2 * math.pi / 3.8);
        bodyScaleY = 1.0 + 0.045 * sleepBreath;
        bodyScaleX = 1.0 + 0.008 * sleepBreath;
        bodyY = -1.4 * sleepBreath;
        headBobY = -1.2 * sleepBreath;
        headBobRot = 0.8 * sleepBreath;

        currentTail = CatVectorGeometry.swayTail(
          CatVectorGeometry.bodySleep['tail']!,
          -5.0 * sleepBreath,
        );
        break;

      case CatPose.pat:
        bodyPts = CatVectorGeometry.bodyPat['body']!;
        headBasePos = const Offset(136, 62);
        headBaseRot = -2.0;
        headScale = 1.09;
        shadowRx = 38.0;
        shadowCx = 108.0;
        shadowOpacity = 0.26;
        currentEyeState = 'happy';
        showGlints = false;
        mouthPts = CatVectorGeometry.mouths['grin']!;

        // Pat squash & elastic rebound
        final patT = (t * 1.4) % 1.0;
        if (patT < 0.25) {
          final squash = math.sin(patT / 0.25 * math.pi);
          bodyScaleY = 1.0 - 0.04 * squash;
          bodyScaleX = 1.0 + 0.03 * squash;
          headBobY = 3.4 * squash;
          headPts = CatVectorGeometry.flattenEars(CatVectorGeometry.headAwake, 6.0 * squash);
        } else {
          final recover = (patT - 0.25) / 0.75;
          final elastic = math.exp(-4 * recover) * math.cos(recover * 3 * math.pi);
          headBobY = -2.0 * elastic;
        }

        // Pleased wagging tail wave
        currentTail = CatVectorGeometry.tailWave(
          CatVectorGeometry.bodyPat['tail']!,
          t * 1.8,
          15.0,
          0.22,
        );
        break;

      case CatPose.greet:
        bodyPts = CatVectorGeometry.bodyGreet['body']!;
        headBasePos = const Offset(136, 55);
        headBaseRot = -9.0;
        headScale = 1.10;
        shadowRx = 36.0;
        shadowCx = 108.0;
        shadowOpacity = 0.24;
        currentEyeState = isBlinking ? 'closed' : 'open';
        mouthPts = CatVectorGeometry.mouths['grin']!;

        // Cheerful bouncing body and tilted head
        final greetBeat = (t * 2.2) % 1.0;
        final bounce = math.sin(greetBeat * math.pi);
        bodyScaleY = 1.0 + 0.022 * bounce;
        bodyY = -1.2 * bounce;
        headBobY = -1.4 * bounce;
        headBobRot = 2.0 * bounce;

        currentTail = CatVectorGeometry.swayTail(
          CatVectorGeometry.bodyGreet['tail']!,
          11.0 * math.sin(t * 3.5),
        );
        break;

      case CatPose.bored:
        bodyPts = CatVectorGeometry.bodyBored['body']!;
        headPts = CatVectorGeometry.headBored;
        earLPts = CatVectorGeometry.earLBored;
        earRPts = CatVectorGeometry.earRBored;
        headBasePos = const Offset(144, 98);
        headBaseRot = 5.0;
        headScale = 1.07;
        shadowRx = 52.0;
        shadowCx = 94.0;
        shadowOpacity = 0.26;
        currentEyeState = 'bored';
        showGlints = false;
        mouthPts = CatVectorGeometry.mouths['flat']!;

        // Head nods off and jerks back up
        final boredCycle = t % 5.2;
        if (boredCycle < 2.5) {
          headBobY = 3.4 * (boredCycle / 2.5);
          headBobRot = 3.0 * (boredCycle / 2.5);
        } else if (boredCycle < 2.82) {
          final snap = (boredCycle - 2.5) / 0.32;
          headBobY = 3.4 * (1.0 - snap);
          headBobRot = 3.0 * (1.0 - snap);
        }

        // Listless tail thumps
        double boredTailAngle = 0.0;
        if (boredCycle > 1.0 && boredCycle < 1.36) {
          boredTailAngle = 13.0 * math.sin((boredCycle - 1.0) / 0.36 * math.pi);
        }
        currentTail = CatVectorGeometry.swayTail(
          CatVectorGeometry.bodyBored['tail']!,
          boredTailAngle,
        );
        break;

      case CatPose.angry:
        bodyPts = CatVectorGeometry.bodyAngry['body']!;
        headPts = CatVectorGeometry.headAngry;
        earLPts = CatVectorGeometry.earLAngry;
        earRPts = CatVectorGeometry.earRAngry;
        headBasePos = const Offset(152, 78);
        headBaseRot = 5.0;
        headScale = 1.00;
        shadowRx = 50.0;
        shadowCx = 94.0;
        shadowOpacity = 0.30;
        currentEyeState = 'angry';
        showGlints = false;
        mouthPts = CatVectorGeometry.mouths['frown']!;
        tailWidth = 10.0;

        // Fast stomping gait
        final stompBob = math.sin(walkPhase * 4 * math.pi);
        bodyY = -2.5 * stompBob.abs();
        headBobY = -3.0 * stompBob.abs();
        headBobRot = -2.0 * stompBob;

        currentTail = CatVectorGeometry.tailWave(
          CatVectorGeometry.bodyAngry['tail']!,
          walkPhase * 0.5,
          6.0,
          0.34,
        );
        break;

      case CatPose.confront:
        bodyPts = CatVectorGeometry.bodyConfront['body']!;
        headPts = CatVectorGeometry.headAngry;
        earLPts = CatVectorGeometry.earLAngry;
        earRPts = CatVectorGeometry.earRAngry;
        headBasePos = const Offset(150, 85);
        headBaseRot = 8.0;
        headScale = 1.01;
        shadowRx = 51.0;
        shadowCx = 95.0;
        shadowOpacity = 0.30;
        currentEyeState = 'angry';
        showGlints = false;
        mouthPts = CatVectorGeometry.mouths['snarl']!;
        tailWidth = 10.0;

        // Fine trembling tension tremor
        final tremor = math.sin(t * 36.0) * 0.7;
        bodyX = tremor;
        headBobX = tremor;

        // Tail lashing
        final lash = math.sin(t * 4.5);
        currentTail = CatVectorGeometry.swayTail(
          CatVectorGeometry.bodyConfront['tail']!,
          lash * 18.0,
        );
        break;
    }

    if (isTwitching) {
      headPts = CatVectorGeometry.flickEars(headPts);
    }

    // -------------------------------------------------------------------------
    // 1. Soft Shadow
    // -------------------------------------------------------------------------
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: shadowOpacity * 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(shadowCx, 138),
        width: shadowRx * 2.0,
        height: 10.0,
      ),
      shadowPaint,
    );

    // -------------------------------------------------------------------------
    // 2. Far Legs (BF, FF) with furShade
    // -------------------------------------------------------------------------
    final legFarPaint = Paint()
      ..color = palette.furShade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (pose == CatPose.walk || pose == CatPose.angry) {
      // Procedural gait
      final legBF = CatVectorGeometry.legFrame(
        const [58.0, 95.0],
        10.0,
        36.0,
        8.0,
        -3.4,
        walkPhase + 0.75,
      );
      final legFF = CatVectorGeometry.legFrame(
        const [114.0, 95.0],
        9.0,
        36.0,
        8.0,
        2.8,
        walkPhase + 0.50,
      );
      canvas.drawPath(CatVectorGeometry.buildSplinePath(legBF, false), legFarPaint);
      canvas.drawPath(CatVectorGeometry.buildSplinePath(legFF, false), legFarPaint);
    } else {
      final poseLegs = _getPoseLegs(pose);
      if (poseLegs != null && poseLegs.containsKey('bf')) {
        canvas.drawPath(CatVectorGeometry.buildSplinePath(poseLegs['bf']!, false), legFarPaint);
      }
      if (poseLegs != null && poseLegs.containsKey('ff')) {
        canvas.drawPath(CatVectorGeometry.buildSplinePath(poseLegs['ff']!, false), legFarPaint);
      }
    }

    // -------------------------------------------------------------------------
    // 3. Body Group (Tail + Body) with Breathing Transform
    // -------------------------------------------------------------------------
    canvas.save();
    // Transform around body root
    const bodyOrigin = Offset(108, 137);
    canvas.translate(bodyOrigin.dx + bodyX, bodyOrigin.dy + bodyY);
    canvas.scale(bodyScaleX, bodyScaleY);
    if (bodyRot != 0) canvas.rotate(bodyRot * CatVectorGeometry.rad);
    canvas.translate(-bodyOrigin.dx, -bodyOrigin.dy);

    // Tail
    final tailPaint = Paint()
      ..color = palette.fur
      ..style = PaintingStyle.stroke
      ..strokeWidth = tailWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(CatVectorGeometry.buildSplinePath(currentTail, false), tailPaint);

    // Body
    final bodyPaint = Paint()
      ..color = palette.fur
      ..style = PaintingStyle.fill;
    canvas.drawPath(CatVectorGeometry.buildSplinePath(bodyPts, true), bodyPaint);
    canvas.restore();

    // -------------------------------------------------------------------------
    // 4. Near Legs (BN, FN) with fur
    // -------------------------------------------------------------------------
    final legNearPaint = Paint()
      ..color = palette.fur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isSwatting) {
      // Swatting strike interpolation: COCK -> STRIKE -> TRAIL
      final legBN = CatVectorGeometry.bodyConfront['bn']!;
      canvas.drawPath(CatVectorGeometry.buildSplinePath(legBN, false), legNearPaint);

      List<List<double>> swatPaw;
      if (swatProgress < 0.35) {
        // Cock back
        final frac = swatProgress / 0.35;
        swatPaw = _lerpPoints(CatVectorGeometry.bodyConfront['fn']!, CatVectorGeometry.swatCock, frac);
      } else if (swatProgress < 0.70) {
        // Strike forward whip
        final frac = (swatProgress - 0.35) / 0.35;
        swatPaw = _lerpPoints(CatVectorGeometry.swatCock, CatVectorGeometry.swatStrike, frac);
      } else {
        // Trail down
        final frac = (swatProgress - 0.70) / 0.30;
        swatPaw = _lerpPoints(CatVectorGeometry.swatStrike, CatVectorGeometry.swatTrail, frac);
      }
      canvas.drawPath(CatVectorGeometry.buildSplinePath(swatPaw, false), legNearPaint);

      // Pawprint impact burst at contact frame
      if (swatProgress >= 0.50 && swatProgress <= 0.85) {
        final burstFrac = (swatProgress - 0.50) / 0.35;
        _drawPawprint(canvas, const Offset(182, 126), burstFrac);
      }
    } else if (pose == CatPose.walk || pose == CatPose.angry) {
      final legBN = CatVectorGeometry.legFrame(
        const [68.0, 94.0],
        10.0,
        36.0,
        8.0,
        -3.4,
        walkPhase + 0.25,
      );
      final legFN = CatVectorGeometry.legFrame(
        const [124.0, 94.0],
        9.0,
        36.0,
        8.0,
        2.8,
        walkPhase + 0.00,
      );
      canvas.drawPath(CatVectorGeometry.buildSplinePath(legBN, false), legNearPaint);
      canvas.drawPath(CatVectorGeometry.buildSplinePath(legFN, false), legNearPaint);
    } else if (pose == CatPose.greet) {
      final legBN = CatVectorGeometry.bodyGreet['bn']!;
      canvas.drawPath(CatVectorGeometry.buildSplinePath(legBN, false), legNearPaint);

      // Foreleg waves back and forth in smooth arc
      final waveProgress = (t * 2.5) % 1.0;
      final waveLerp = (math.sin(waveProgress * 2 * math.pi) + 1.0) / 2.0;
      final wavingPaw = _lerpPoints(
        CatVectorGeometry.bodyGreet['fnWaveBack']!,
        CatVectorGeometry.bodyGreet['fnWaveOut']!,
        waveLerp,
      );
      canvas.drawPath(CatVectorGeometry.buildSplinePath(wavingPaw, false), legNearPaint);
    } else {
      final poseLegs = _getPoseLegs(pose);
      if (poseLegs != null && poseLegs.containsKey('bn')) {
        canvas.drawPath(CatVectorGeometry.buildSplinePath(poseLegs['bn']!, false), legNearPaint);
      }
      if (poseLegs != null && poseLegs.containsKey('fn')) {
        canvas.drawPath(CatVectorGeometry.buildSplinePath(poseLegs['fn']!, false), legNearPaint);
      }
    }

    // -------------------------------------------------------------------------
    // 5. Head Group (Head, Inner Ears, Blush, Eyes, Glints, Mouth)
    // -------------------------------------------------------------------------
    canvas.save();
    // Head placement & bobbing
    canvas.translate(headBasePos.dx + headBobX, headBasePos.dy + headBobY);
    final totalHeadRot = headBaseRot + headBobRot;
    if (totalHeadRot != 0) canvas.rotate(totalHeadRot * CatVectorGeometry.rad);
    canvas.scale(headScale, headScale);

    // Head fur
    final headPaint = Paint()
      ..color = palette.fur
      ..style = PaintingStyle.fill;
    canvas.drawPath(CatVectorGeometry.buildSplinePath(headPts, true), headPaint);

    // Inner Ears
    final earPaint = Paint()
      ..color = palette.ear.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawPath(CatVectorGeometry.buildSplinePath(earLPts, true), earPaint);
    canvas.drawPath(CatVectorGeometry.buildSplinePath(earRPts, true), earPaint);

    // Blush Cheeks (except angry)
    if (pose != CatPose.angry && pose != CatPose.confront) {
      final blushPaint = Paint()
        ..color = palette.blush.withValues(alpha: 0.50)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        const Rect.fromLTWH(-21.5 - 7.6, 9.4 - 3.8, 15.2, 7.6),
        blushPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(21.5 - 7.6, 9.4 - 3.8, 15.2, 7.6),
        blushPaint,
      );
    }

    // Eyes
    final eyePaint = Paint()
      ..color = palette.face
      ..style = PaintingStyle.fill;

    List<List<double>> eyeLPts;
    List<List<double>> eyeRPts;
    switch (currentEyeState) {
      case 'closed':
        eyeLPts = CatVectorGeometry.eyeClosed(-11.5, 0.4);
        eyeRPts = CatVectorGeometry.eyeClosed(11.5, 0.4);
        break;
      case 'happy':
        eyeLPts = CatVectorGeometry.eyeHappy(-11.5, 0.4);
        eyeRPts = CatVectorGeometry.eyeHappy(11.5, 0.4);
        break;
      case 'angry':
        eyeLPts = CatVectorGeometry.eyeAngry(-11.5, 0.4, 1);
        eyeRPts = CatVectorGeometry.eyeAngry(11.5, 0.4, -1);
        break;
      case 'bored':
        eyeLPts = CatVectorGeometry.eyeBored(-11.5, 0.4);
        eyeRPts = CatVectorGeometry.eyeBored(11.5, 0.4);
        break;
      case 'open':
      default:
        eyeLPts = CatVectorGeometry.eyeOpen(-11.5, 0.4);
        eyeRPts = CatVectorGeometry.eyeOpen(11.5, 0.4);
        break;
    }

    canvas.drawPath(CatVectorGeometry.buildSplinePath(eyeLPts, true), eyePaint);
    canvas.drawPath(CatVectorGeometry.buildSplinePath(eyeRPts, true), eyePaint);

    // Dual Catchlights (glints) on open eyes
    if (showGlints && glintOpacity > 0.0) {
      final glintPaint = Paint()
        ..color = Colors.white.withValues(alpha: glintOpacity)
        ..style = PaintingStyle.fill;
      // Left eye glints
      canvas.drawCircle(const Offset(-13.4, -2.0), 2.15, glintPaint);
      canvas.drawCircle(const Offset(-9.2, 2.6), 1.05, glintPaint);
      // Right eye glints
      canvas.drawCircle(const Offset(9.6, -2.0), 2.15, glintPaint);
      canvas.drawCircle(const Offset(13.8, 2.6), 1.05, glintPaint);
    }

    // Mouth
    final mouthPaint = Paint()
      ..color = palette.face
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(CatVectorGeometry.buildSplinePath(mouthPts, false), mouthPaint);

    canvas.restore(); // Head group restore

    // -------------------------------------------------------------------------
    // 6. Floating Props (Zzz, Hearts, Anger Vein, Pawprint)
    // -------------------------------------------------------------------------
    if (pose == CatPose.sleep) {
      _drawFloatingZzz(canvas, t, palette.fur);
    } else if (pose == CatPose.pat) {
      _drawFloatingHearts(canvas, t);
    } else if (pose == CatPose.angry || pose == CatPose.confront) {
      _drawAngerMark(canvas, t, const Offset(174, 38));
    }

    canvas.restore(); // Overall Canvas restore
  }

  // ---------------------------------------------------------------------------
  // Helper: Get legs for static poses
  // ---------------------------------------------------------------------------
  Map<String, List<List<double>>>? _getPoseLegs(CatPose pose) {
    switch (pose) {
      case CatPose.sit:
        return CatVectorGeometry.bodySit;
      case CatPose.sleep:
        return CatVectorGeometry.bodySleep;
      case CatPose.pat:
        return CatVectorGeometry.bodyPat;
      case CatPose.greet:
        return CatVectorGeometry.bodyGreet;
      case CatPose.bored:
        return CatVectorGeometry.bodyBored;
      case CatPose.confront:
        return CatVectorGeometry.bodyConfront;
      default:
        return CatVectorGeometry.bodySit;
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: Point linear interpolation
  // ---------------------------------------------------------------------------
  List<List<double>> _lerpPoints(
      List<List<double>> a, List<List<double>> b, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    return List.generate(math.min(a.length, b.length), (i) {
      final x = a[i][0] + (b[i][0] - a[i][0]) * clampedT;
      final y = a[i][1] + (b[i][1] - a[i][1]) * clampedT;
      return [x, y];
    });
  }

  // ---------------------------------------------------------------------------
  // Helper: Floating Zzz for sleep
  // ---------------------------------------------------------------------------
  void _drawFloatingZzz(Canvas canvas, double t, Color color) {
    for (int i = 0; i < 3; i++) {
      final p = ((t * 0.45) + (i * 0.33)) % 1.0;
      final x = 166.0 + p * 16.0;
      final y = 92.0 - p * 36.0;
      final opacity = math.sin(p * math.pi).clamp(0.0, 0.9);
      final scale = 0.65 + p * 0.7;

      final textSpan = TextSpan(
        text: 'z',
        style: TextStyle(
          color: color.withValues(alpha: opacity),
          fontSize: 13.0 * scale,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((p * 20.0 - 10.0) * CatVectorGeometry.rad);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: Floating Hearts for pat
  // ---------------------------------------------------------------------------
  void _drawFloatingHearts(Canvas canvas, double t) {
    for (int i = 0; i < 2; i++) {
      final p = ((t * 0.7) + (i * 0.5)) % 1.0;
      final drift = (i == 0) ? -16.0 : 18.0;
      final x = 154.0 + drift * p;
      final y = 48.0 - p * 38.0;
      final opacity = math.sin(p * math.pi).clamp(0.0, 1.0);
      final scale = 0.4 + p * 0.7;

      final heartPath = Path()
        ..moveTo(0, 4.2)
        ..cubicTo(-5.4, -1.2, -4.2, -7.4, 0, -3.6)
        ..cubicTo(4.2, -7.4, 5.4, -1.2, 0, 4.2)
        ..close();

      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);
      canvas.rotate((drift > 0 ? 14 : -14) * CatVectorGeometry.rad);

      final heartPaint = Paint()
        ..color = const Color(0xFFE07A8C).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(heartPath, heartPaint);
      canvas.restore();
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: Anime Anger Vein Mark 💢
  // ---------------------------------------------------------------------------
  void _drawAngerMark(Canvas canvas, double t, Offset center) {
    final throb = 1.0 + 0.14 * math.sin(t * 12.0);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(throb);

    final fillPaint = Paint()
      ..color = const Color(0xFFE2584F)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF2B2F3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < 4; i++) {
      final angle = (i * 90.0) * CatVectorGeometry.rad;
      canvas.save();
      canvas.rotate(angle);
      final arcPath = Path()
        ..moveTo(3.0, 3.0)
        ..lineTo(7.5, 3.0)
        ..lineTo(7.5, 7.5)
        ..lineTo(3.0, 7.5)
        ..close();
      canvas.drawPath(arcPath, fillPaint);
      canvas.drawPath(arcPath, strokePaint);
      canvas.restore();
    }
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Helper: Pawprint Burst on Swat Impact
  // ---------------------------------------------------------------------------
  void _drawPawprint(Canvas canvas, Offset pos, double frac) {
    final scale = 0.5 + frac * 0.8;
    final opacity = (1.0 - frac).clamp(0.0, 0.95);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final fillPaint = Paint()
      ..color = const Color(0xFFF6F1E4).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF2B2F3A).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeJoin = StrokeJoin.round;

    // Pad
    final pad = Path()
      ..addOval(const Rect.fromLTWH(-5.0, -3.0, 10.0, 8.0));
    canvas.drawPath(pad, fillPaint);
    canvas.drawPath(pad, strokePaint);

    // 4 Toes
    final toeOffsets = [
      const Offset(-4.5, -6.5),
      const Offset(-1.5, -8.0),
      const Offset(2.0, -8.0),
      const Offset(5.0, -6.5),
    ];
    for (final off in toeOffsets) {
      final toe = Path()..addOval(Rect.fromCenter(center: off, width: 3.2, height: 3.8));
      canvas.drawPath(toe, fillPaint);
      canvas.drawPath(toe, strokePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FocusCatVectorPainter oldDelegate) {
    return true; // continuous 60fps animation
  }
}
