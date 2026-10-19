// lib/views/home_screen.dart
// Root compositing screen — optimized for iPhone Dynamic Island, iOS notch, and gestures.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/cat_viewmodel.dart';
import '../views/focus_dashboard_view.dart';
import '../widgets/cat_stage_widget.dart';
import '../widgets/chat_command_box.dart';
import '../widgets/playground_card.dart';
import '../widgets/top_status_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off async init after first frame so context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatViewModel>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF060809),
      ),
      child: GestureDetector(
        // iOS tap-to-dismiss keyboard behavior
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // Main content layout (safely within borders)
              SafeArea(
                bottom: true,
                top: true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // 1. Patrol status + iOS Tray Action Sheet (with central Dynamic Island gap)
                      const TopStatusBar(),
                      const SizedBox(height: 10),

                      // 2. FocusCat rig sandbox card
                      const PlaygroundCard(),
                      const SizedBox(height: 8),

                      // 3. Focus & Patrol Companion Dashboard
                      const Expanded(child: FocusDashboardView()),
                      const SizedBox(height: 8),

                      // 4. Chat command box (animates in/out)
                      const ChatCommandBox(),

                      // Gap when chat is open
                      Selector<CatViewModel, bool>(
                        selector: (_, m) => m.isChatOpen,
                        builder: (_, open, __) => SizedBox(height: open ? 8 : 0),
                      ),

                      // 5. Taskbar hint bar (Double-tap to reset cat position!)
                      _buildBottomHintBar(context, vm),
                    ],
                  ),
                ),
              ),

              // Dynamic Island Cat Perch & 2D Free Dragging Overlay Layer
              if (!vm.isSettingsOpen)
                const Positioned.fill(
                  child: CatStageWidget(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomHintBar(BuildContext context, CatViewModel vm) {
    return GestureDetector(
      onDoubleTap: () {
        HapticFeedback.lightImpact();
        vm.resetCatPosition();
      },
      child: Container(
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
            Flexible(
              child: Text(
                'Dynamic Island Cat · Drag anywhere · Double-tap bar to reset · 1-tap purr · 2-tap chat',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
