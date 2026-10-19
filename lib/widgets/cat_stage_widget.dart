// lib/widgets/cat_stage_widget.dart
// Interactive vector cat stage with 2D free dragging, triple-tap detection,
// dynamic size scaling, and speech bubble pointer.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
    _tapTimer = Timer(const Duration(milliseconds: 320), () {
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

    if (vm.isHidden) {
      return const SizedBox.shrink();
    }

    // Dynamic scale driven by the "Size" slider in settings
    final double catW = 168.0 * vm.catScale;
    final double catH = 126.0 * vm.catScale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ---------------------------------------------------------------------
        // 2D Floating Speech Bubble & Cat (Draggable anywhere on screen!)
        // ---------------------------------------------------------------------
        Transform.translate(
          offset: Offset(vm.catXOffset, vm.catYOffset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speech bubble
              AnimatedSlide(
                offset: vm.isChatOpen ? Offset.zero : const Offset(0, 0.04),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12161F),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFF2A3244)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        vm.speechBubble,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE8EAF0),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    // Pointer tail
                    Transform.translate(
                      offset: const Offset(0, -4.5),
                      child: Transform.rotate(
                        angle: 45 * math.pi / 180,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFF12161F),
                            border: Border(
                              right: BorderSide(color: Color(0xFF2A3244)),
                              bottom: BorderSide(color: Color(0xFF2A3244)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              // Vector Cat with 2D Dragging & Multi-tap
              GestureDetector(
                onTap: () => _handleTap(context, vm),
                onPanUpdate: (d) => vm.onCatDrag2D(d.delta.dx, d.delta.dy),
                onPanEnd: (_) => vm.onCatDragEnd(),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: catW,
                  height: catH,
                  child: AnimatedBuilder(
                    animation:
                        Listenable.merge([_animController, _swatController]),
                    builder: (context, child) {
                      // Animation time scaled by user's "Animation speed" slider
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
            ],
          ),
        ),

        const SizedBox(height: 6),

        // ---------------------------------------------------------------------
        // Taskbar / Floor Hint Bar
        // ---------------------------------------------------------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0D10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1C2630)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6.5,
                height: 6.5,
                decoration: BoxDecoration(
                  color: vm.isPatrolling
                      ? const Color(0xFF4ADE80)
                      : Colors.amberAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (vm.isPatrolling
                              ? const Color(0xFF4ADE80)
                              : Colors.amberAccent)
                          .withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Drag anywhere · 1-tap purr · 2-tap chat · 3-tap settings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
