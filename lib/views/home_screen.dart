// lib/views/home_screen.dart
// Root compositing screen — optimized for iOS notch, Dynamic Island, and gestures.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/cat_viewmodel.dart';
import '../views/browser_workspace_view.dart';
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
          body: SafeArea(
            bottom: true,
            top: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // 1. Patrol status + iOS Tray Action Sheet
                  const TopStatusBar(),
                  const SizedBox(height: 12),

                  // 2. Official FocusCat rig sandbox card
                  const PlaygroundCard(),
                  const SizedBox(height: 10),

                  // 3. Watch & Close browser workspace
                  const Expanded(child: BrowserWorkspaceView()),
                  const SizedBox(height: 8),

                  // 4. Chat command box (animates in/out)
                  const ChatCommandBox(),

                  // Gap when chat is open
                  Selector<CatViewModel, bool>(
                    selector: (_, vm) => vm.isChatOpen,
                    builder: (_, open, __) => SizedBox(height: open ? 8 : 0),
                  ),

                  // 5. Official FocusCat vector stage
                  const CatStageWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
