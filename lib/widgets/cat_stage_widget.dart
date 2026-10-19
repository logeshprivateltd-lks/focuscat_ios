// lib/widgets/cat_stage_widget.dart
// Interactive Dynamic Island perched vector cat with bounded 2D free dragging,
// multi-tap gesture detection, speech bubble, and smooth snap-back mechanics.
// The cat lives completely free on the phone screen without any enclosing tab or window box.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/cat_models.dart';
import '../painters/focus_cat_vector_painter.dart';
import '../viewmodels/cat_viewmodel.dart';

class CatStageWidget extends StatefulWidget {
  const CatStageWidget({super.key});

  @override
  State<CatStageWidget> createState() => _CatStageWidgetState();
}

class _CatStageWidgetState extends State<CatStageWidget>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final AnimationController _swatController;
  final Stopwatch _stopwatch = Stopwatch();

  bool _lastSwattingState = false;

  // Multi-tap counter for 1-tap (pet), 2-tap (chat), 3-tap (main settings)
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _swatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _stopwatch.stop();
    _animController.dispose();
    _swatController.dispose();
    super.dispose();
  }

  void _checkSwatState(bool isSwatting) {
    if (isSwatting && !_lastSwattingState) {
      _swatController.forward(from: 0.0);
    }
    _lastSwattingState = isSwatting;
  }

  void _handleTap(BuildContext context, CatViewModel vm) {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_tapCount == 1) {
        vm.onCatTap();
      } else if (_tapCount == 2) {
        vm.onCatDoubleTap();
      } else if (_tapCount >= 3) {
        vm.onCatTripleTap(context);
      }
      _tapCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatViewModel>();
    _checkSwatState(vm.isSwattingInProgress);

    if (vm.isHidden || vm.isSettingsOpen) {
      return const SizedBox.shrink();
    }

    final topPadding = MediaQuery.of(context).padding.top;
    final isPerchedOnIsland =
        vm.catXOffset.abs() < 14 && vm.catYOffset.abs() < 14;

    // Cat size: on Dynamic Island perch, compact 48x36 * scale;
    // when dragged freely, scales up to 64x48 * scale
    final baseWidth = isPerchedOnIsland ? 50.0 : 64.0;
    final baseHeight = isPerchedOnIsland ? 38.0 : 48.0;
    final catW = baseWidth * vm.catScale;
    final catH = baseHeight * vm.catScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;

        // Strict clamp bounds within screen: allows cat to reach the very bottom bezel
        final maxDragX = (screenW / 2) - (catW / 2) - 12.0;
        final minDragX = -maxDragX;
        final minDragY = 0.0;
        final maxDragY = math.max(0.0, screenH - topPadding - catH - 18.0);
        final isNearBottom = vm.catYOffset > (maxDragY * 0.65);
        final isLyingOnBottom = vm.catYOffset >= (maxDragY - 30.0);

        return Stack(
          children: [
            Positioned(
              top: topPadding + 4 + vm.catYOffset,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(vm.catXOffset, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // When cat is near bottom of phone screen, speech bubble appears ABOVE cat
                      if (isNearBottom) ...[
                        _buildSpeechBubble(vm, pointerAtBottom: true),
                        const SizedBox(height: 6),
                      ],

                      // Cat & Interactive Gestures (completely free of any window or tab box)
                      GestureDetector(
                        onTap: () => _handleTap(context, vm),
                        onPanUpdate: (d) => vm.onCatDrag2D(
                          d.delta.dx,
                          d.delta.dy,
                          minX: minDragX,
                          maxX: maxDragX,
                          minY: minDragY,
                          maxY: maxDragY,
                        ),
                        onPanEnd: (_) => vm.onCatDragEnd(maxY: maxDragY),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: catW,
                          height: catH,
                          decoration: BoxDecoration(
                            boxShadow: [
                              if (isLyingOnBottom || vm.pose == CatPose.sleep)
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.20),
                                  blurRadius: 18,
                                  spreadRadius: 3,
                                )
                              else if (isPerchedOnIsland)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                            ],
                          ),
                          child: AnimatedBuilder(
                            animation: Listenable.merge(
                                [_animController, _swatController]),
                            builder: (context, child) {
                              final elapsedSeconds =
                                  (_stopwatch.elapsedMilliseconds / 1000.0) *
                                      vm.animSpeed;
                              return CustomPaint(
                                size: Size(catW, catH),
                                painter: FocusCatVectorPainter(
                                  pose: vm.pose,
                                  palette: vm.catColor,
                                  facingRight: vm.facingRight,
                                  animationTime: elapsedSeconds,
                                  isSwatting: vm.isSwattingInProgress,
                                  swatProgress: _swatController.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // When cat is at top or middle, speech bubble appears BELOW cat
                      if (!isNearBottom) ...[
                        const SizedBox(height: 6),
                        _buildSpeechBubble(vm, pointerAtBottom: false),
                      ],

                      // Floating Quick Chips when dragged away from perch
                      if (!isPerchedOnIsland) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Return to Island
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                vm.resetCatPosition();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141A24)
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFF38BDF8)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.arrow_up_to_line,
                                        size: 11, color: Color(0xFF38BDF8)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Island Perch 🏝️',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF38BDF8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Lie Down on Phone
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                vm.lieDownOnPhone(targetY: maxDragY);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1705)
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFFFBBF24)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.bed_double_fill,
                                        size: 11, color: Color(0xFFFBBF24)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Lie on Phone 🐾',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFBBF24),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeechBubble(CatViewModel vm, {required bool pointerAtBottom}) {
    return AnimatedSlide(
      offset: vm.isChatOpen ? Offset.zero : const Offset(0, 0.02),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!pointerAtBottom)
            // Pointer tail pointing UP towards cat
            Transform.rotate(
              angle: 45 * math.pi / 180,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF12161F),
                  border: Border(
                    left: BorderSide(color: Color(0xFF2A3244)),
                    top: BorderSide(color: Color(0xFF2A3244)),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(0, pointerAtBottom ? 4 : -4),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF12161F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3244)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                vm.speechBubble,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE8EAF0),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  wordSpacing: 0,
                ),
              ),
            ),
          ),
          if (pointerAtBottom)
            // Pointer tail pointing DOWN towards cat
            Transform.rotate(
              angle: 45 * math.pi / 180,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF12161F),
                  border: Border(
                    right: BorderSide(color: Color(0xFF2A3244)),
                    bottom: BorderSide(color: Color(0xFF2A3244)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
