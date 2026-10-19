// lib/widgets/cat_stage_widget.dart
// Interactive Dynamic Island perched vector cat with bounded 2D free dragging,
// multi-tap gesture detection, speech bubble, and smooth snap-back mechanics.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
        vm.catXOffset.abs() < 12 && vm.catYOffset.abs() < 12;

    // Cat size: on Dynamic Island perch, compact 48x36 * scale;
    // when dragged freely, scales up to 64x48 * scale
    final baseWidth = isPerchedOnIsland ? 48.0 : 64.0;
    final baseHeight = isPerchedOnIsland ? 36.0 : 48.0;
    final catW = baseWidth * vm.catScale;
    final catH = baseHeight * vm.catScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;

        // Strict clamp bounds within SafeArea
        final maxDragX = (screenW / 2) - (catW / 2) - 12.0;
        final minDragX = -maxDragX;
        final minDragY = 0.0;
        final maxDragY = math.max(0.0, screenH - topPadding - 180.0);

        return Stack(
          children: [
            Positioned(
              top: topPadding + 6 + vm.catYOffset,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(vm.catXOffset, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dynamic Island Perch Pill (rendered when hugging the top center)
                      if (isPerchedOnIsland)
                        Container(
                          width: 124,
                          height: 34,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF222834),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.9),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: vm.isPatrolling
                                        ? const Color(0xFF4ADE80)
                                        : Colors.orangeAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Text(
                                vm.isPatrolling ? 'PATROL' : 'PAUSED',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF9AA8B4),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  vm.focusSecondsRemaining > 0
                                      ? vm.formatTime(vm.focusSecondsRemaining)
                                      : '🐾',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4ADE80),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Cat & Interactive Gestures
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
                        onPanEnd: (_) => vm.onCatDragEnd(),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: catW,
                          height: catH,
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

                      const SizedBox(height: 4),

                      // Speech Bubble (placed right below cat)
                      AnimatedSlide(
                        offset:
                            vm.isChatOpen ? Offset.zero : const Offset(0, 0.02),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                              offset: const Offset(0, -4),
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF12161F),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF2A3244)),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.8),
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
                          ],
                        ),
                      ),

                      // "Reset Cat Position (Return to Perch)" chip when dragged away
                      if (!isPerchedOnIsland) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            vm.resetCatPosition();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141A24)
                                  .withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFF38BDF8)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.arrow_up_to_line,
                                    size: 11, color: Color(0xFF38BDF8)),
                                SizedBox(width: 5),
                                Text(
                                  'Return Home Perch 🏝️',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}
