// lib/views/main_settings_window.dart
// Desktop-class Control Center & Settings window matching https://gokulbuilds.com/focuscat/
// Exactly replicates the desktop settings UI from the user screenshot.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/cat_models.dart';
import '../services/cat_sound_service.dart';
import '../viewmodels/cat_viewmodel.dart';

class MainSettingsWindow extends StatefulWidget {
  final String initialTab;
  const MainSettingsWindow({super.key, this.initialTab = 'The cat'});

  static void show(BuildContext context, {String initialTab = 'The cat'}) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: MainSettingsWindow(initialTab: initialTab),
      ),
    );
  }

  @override
  State<MainSettingsWindow> createState() => _MainSettingsWindowState();
}

class _MainSettingsWindowState extends State<MainSettingsWindow> {
  late String _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatViewModel>();
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Container(
      width: 760,
      height: 620,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2838)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          // -------------------------------------------------------------------
          // Window Title Bar (Mac/Windows desktop chrome)
          // -------------------------------------------------------------------
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F141E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Color(0xFF1A2230))),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.paw_solid,
                  size: 14,
                  color: Color(0xFF4ADE80),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FocusCat — Settings',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFF9AA8B4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF9AA8B4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // Window Body: Left Sidebar + Right Content Pane
          // -------------------------------------------------------------------
          Expanded(
            child: Row(
              children: [
                // Left Navigation Sidebar
                _buildSidebar(vm, isCompact),

                // Vertical Divider
                Container(width: 1, color: const Color(0xFF161E2C)),

                // Right Content Area
                Expanded(
                  child: Container(
                    color: const Color(0xFF0B0E16),
                    child: _buildTabContent(vm),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar Navigation (Matches user screenshot)
  // ---------------------------------------------------------------------------
  Widget _buildSidebar(CatViewModel vm, bool isCompact) {
    final navItems = [
      'Patrol',
      'Focus',
      'Session',
      'Reminders',
      'Notes',
      'The cat',
      'Startup',
      'About',
    ];

    return Container(
      width: isCompact ? 100 : 160,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: const Color(0xFF0D121B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Cat Icon + FocusCat + Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2332),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.paw_solid,
                      size: 14,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FocusCat',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                      Text(
                        vm.isPatrolling ? 'on patrol' : 'paused',
                        style: TextStyle(
                          fontSize: 10,
                          color: vm.isPatrolling
                              ? const Color(0xFF4ADE80)
                              : Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Nav Links
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (context, i) {
                final item = navItems[i];
                final isSelected = _currentTab == item;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentTab = item);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF182232)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? const Border(
                                left: BorderSide(
                                    color: Color(0xFF4ADE80), width: 3),
                              )
                            : null,
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFE6EDF3)
                              : const Color(0xFF8B98A5),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom "saved" pill (From user screenshot)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF11221A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1C422D)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 10, color: Color(0xFF4ADE80)),
                SizedBox(width: 4),
                Text(
                  'saved',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Right Pane: Active Tab Content
  // ---------------------------------------------------------------------------
  Widget _buildTabContent(CatViewModel vm) {
    switch (_currentTab) {
      case 'The cat':
        return _buildTheCatTab(vm);
      case 'Patrol':
        return _buildPatrolTab(vm);
      case 'Focus':
        return _buildFocusTab(vm);
      case 'Session':
        return _buildSessionTab(vm);
      case 'Reminders':
        return _buildRemindersTab(vm);
      case 'Notes':
        return _buildNotesTab(vm);
      case 'Startup':
        return _buildStartupTab(vm);
      case 'About':
      default:
        return _buildAboutTab(vm);
    }
  }

  // ---------------------------------------------------------------------------
  // Tab 1: "The cat" (Exact replica of user screenshot!)
  // ---------------------------------------------------------------------------
  Widget _buildTheCatTab(CatViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Card 1: Size & Animation Speed Sliders
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            children: [
              // Size Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Size',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                  Text(
                    '${vm.catScale.toStringAsFixed(2)}× — how big it is on screen.',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF8B98A5),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF4ADE80),
                  inactiveTrackColor: const Color(0xFF243040),
                  thumbColor: const Color(0xFF4ADE80),
                  trackHeight: 3.5,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                ),
                child: Slider(
                  value: vm.catScale,
                  min: 0.50,
                  max: 1.60,
                  onChanged: (v) => vm.setCatScale(v),
                ),
              ),

              const SizedBox(height: 10),

              // Animation speed Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Animation speed',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                  Text(
                    '${vm.animSpeed.toStringAsFixed(2)}× — how fast it moves.',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF8B98A5),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF22D3EE),
                  inactiveTrackColor: const Color(0xFF243040),
                  thumbColor: const Color(0xFF22D3EE),
                  trackHeight: 3.5,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                ),
                child: Slider(
                  value: vm.animSpeed,
                  min: 0.30,
                  max: 2.00,
                  onChanged: (v) => vm.setAnimSpeed(v),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Card 2: Checkboxes from user screenshot
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            children: [
              // 1. Wander along bottom of screen
              _buildCheckboxRow(
                title: 'Wander along the bottom of the screen',
                description: 'Off keeps it parked where you drag it.',
                value: vm.wanderEnabled,
                onChanged: (v) => vm.setWanderEnabled(v),
              ),
              const Divider(height: 22, color: Color(0xFF182230)),

              // 2. Type along when I type
              _buildCheckboxRow(
                title: 'Type along when I type',
                description:
                    'The cat sits down at a little keyboard and taps away while you are typing, then packs up when you stop.',
                value: vm.typeAlongEnabled,
                onChanged: (v) => vm.setTypeAlongEnabled(v),
              ),
              const Divider(height: 22, color: Color(0xFF182230)),

              // 3. Follow mouse / finger
              _buildCheckboxRow(
                title: 'Follow the finger / drag',
                description:
                    'The cat walks along to keep up with your drag, and watches it with its eyes. With Wander off it stays parked.',
                value: vm.followFinger,
                onChanged: (v) => vm.setFollowFinger(v),
              ),
              const Divider(height: 22, color: Color(0xFF182230)),

              // 4. Doze off between wanders
              _buildCheckboxRow(
                title: 'Doze off between wanders',
                description: 'Adds the sleeping loaf to its idle rotation.',
                value: vm.dozeOffBetweenWanders,
                onChanged: (v) => vm.setDozeOffBetweenWanders(v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Card 3: Mood & Mode Lock (Solves user's prompt!)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Cat Mood & Mode',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                  const Spacer(),
                  // Lock toggle
                  Row(
                    children: [
                      Icon(
                        vm.isMoodLocked ? Icons.lock : Icons.lock_open,
                        size: 13,
                        color: vm.isMoodLocked
                            ? const Color(0xFF4ADE80)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vm.isMoodLocked ? 'Mood Locked' : 'Auto Mood',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: vm.isMoodLocked
                              ? const Color(0xFF4ADE80)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      CupertinoSwitch(
                        value: vm.isMoodLocked,
                        activeTrackColor: const Color(0xFF4ADE80),
                        onChanged: (v) => vm.setMoodLock(v, vm.pose),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Once assigned, the cat constantly maintains this mood without changing.',
                style: TextStyle(fontSize: 11, color: Color(0xFF8B98A5)),
              ),
              const SizedBox(height: 10),

              // Pose selection chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: CatPose.values.map((p) {
                  final isSelected = vm.pose == p;
                  return ChoiceChip(
                    label: Text(
                      p.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isSelected
                            ? const Color(0xFF04120A)
                            : const Color(0xFFE6EDF3),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF4ADE80),
                    backgroundColor: const Color(0xFF161F2C),
                    showCheckmark: false,
                    onSelected: (_) {
                      vm.setPose(p);
                      vm.setMoodLock(true, p);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Card 4: Sound Options
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cat Sounds & Audio Feedback',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                  CupertinoSwitch(
                    value: vm.soundEnabled,
                    activeTrackColor: const Color(0xFF4ADE80),
                    onChanged: (v) => vm.setSoundEnabled(v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _testSoundBtn('Purr', () => CatSoundService.instance.playPurr()),
                  const SizedBox(width: 6),
                  _testSoundBtn('Meow', () => CatSoundService.instance.playMeow()),
                  const SizedBox(width: 6),
                  _testSoundBtn('Chime', () => CatSoundService.instance.playTimerChime()),
                  const SizedBox(width: 6),
                  _testSoundBtn('Swat', () => CatSoundService.instance.playSwat()),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Bottom Action Section: "SEE WHAT IT DOES"
        const Text(
          'SEE WHAT IT DOES',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 1.2,
            color: Color(0xFF6B7A8A),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4080E0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                vm.demoCycle();
              },
              child: const Text(
                'Show me what it does',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B98A5),
                side: const BorderSide(color: Color(0xFF263244)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => vm.toggleHidden(),
              child: Text(
                vm.isHidden ? 'Show the cat' : 'Hide the cat',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper row for checkboxes
  Widget _buildCheckboxRow({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoCheckbox(
          value: value,
          activeColor: const Color(0xFF4ADE80),
          checkColor: Colors.black,
          onChanged: (v) => onChanged(v ?? false),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE6EDF3),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8B98A5),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _testSoundBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2230),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2E3D52)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF22D3EE),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Patrol & Apple Screen Time for YouTube/Instagram
  // ---------------------------------------------------------------------------
  Widget _buildPatrolTab(CatViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Screen Time Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.hourglass,
                    color: Color(0xFF4ADE80),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Apple Screen Time & Native App Limits',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF122E1F),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Shield Active',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'FocusCat monitors YouTube and Instagram app usage. When daily minutes run out, the cat swats and locks the app.',
                style: TextStyle(fontSize: 11, color: Color(0xFF8B98A5)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Target Apps to Control',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE6EDF3),
          ),
        ),
        const SizedBox(height: 8),

        // Apps list
        ...vm.screenTimeApps.map((app) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1520),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2838)),
            ),
            child: Row(
              children: [
                _buildAppIcon(app.appName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                      Text(
                        'Limit: ${app.dailyMinutes}m · Used: ${(app.secondsUsedToday / 60).toStringAsFixed(1)}m',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8B98A5)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.minus_circle,
                      color: Colors.orangeAccent, size: 20),
                  onPressed: () => vm.updateScreenTimeAppMinutes(app, -5),
                ),
                Text(
                  '${app.dailyMinutes}m',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE6EDF3),
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.plus_circle,
                      color: Color(0xFF4ADE80), size: 20),
                  onPressed: () => vm.updateScreenTimeAppMinutes(app, 5),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAppIcon(String appName) {
    IconData iconData;
    Color iconColor;

    switch (appName.toLowerCase()) {
      case 'youtube':
        iconData = CupertinoIcons.play_rectangle_fill;
        iconColor = Colors.redAccent;
        break;
      case 'instagram':
        iconData = CupertinoIcons.camera_fill;
        iconColor = Colors.pinkAccent;
        break;
      case 'tiktok':
        iconData = CupertinoIcons.music_note_2;
        iconColor = const Color(0xFF00F2FE);
        break;
      case 'x / twitter':
        iconData = CupertinoIcons.number;
        iconColor = const Color(0xFF1DA1F2);
        break;
      case 'reddit':
        iconData = CupertinoIcons.chat_bubble_2_fill;
        iconColor = Colors.deepOrangeAccent;
        break;
      default:
        iconData = CupertinoIcons.app_fill;
        iconColor = const Color(0xFF4ADE80);
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(iconData, color: iconColor, size: 18),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Focus
  // ---------------------------------------------------------------------------
  Widget _buildFocusTab(CatViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Focus Session & Pomodoro',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE6EDF3),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Set a block of distraction-free work. When it ends, the cat chimes and prompts a break.',
                style: TextStyle(fontSize: 11, color: Color(0xFF8B98A5)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                      foregroundColor: const Color(0xFF04120A),
                    ),
                    onPressed: () {
                      vm.chatController.text = '/timer 25';
                      vm.submitInput();
                      Navigator.pop(context);
                    },
                    child: const Text('Start 25m Pomodoro',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9AA8B4),
                    ),
                    onPressed: () {
                      vm.chatController.text = '/timer 50';
                      vm.submitInput();
                      Navigator.pop(context);
                    },
                    child: const Text('Start 50m Deep Work'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 4: Session stats
  // ---------------------------------------------------------------------------
  Widget _buildSessionTab(CatViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today\'s Patrol Log',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE6EDF3),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Swatted ${vm.closedTabsToday.length} tab(s) / app(s) today:',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8B98A5)),
              ),
              const SizedBox(height: 8),
              if (vm.closedTabsToday.isEmpty)
                const Text('No distracting tabs swatted today! 🎉',
                    style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12))
              else
                ...vm.closedTabsToday.map(
                  (tab) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.clear_circled_solid,
                            size: 14, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(tab,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Color(0xFFE6EDF3))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 5: Reminders
  // ---------------------------------------------------------------------------
  Widget _buildRemindersTab(CatViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.drop_fill,
                          color: Color(0xFF38BDF8), size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Hourly Water Reminder',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                    ],
                  ),
                  CupertinoSwitch(
                    value: vm.waterReminderEnabled,
                    activeTrackColor: const Color(0xFF4ADE80),
                    onChanged: (v) => vm.setWaterReminderEnabled(v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 6: Notes
  // ---------------------------------------------------------------------------
  Widget _buildNotesTab(CatViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Quick Notes (${vm.notes.length})',
            style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE6EDF3))),
        const SizedBox(height: 8),
        if (vm.notes.isEmpty)
          const Text('No notes yet. Type a note in the chat box!')
        else
          ...vm.notes.map((n) => ListTile(
                title: Text(n.text,
                    style: const TextStyle(color: Color(0xFFE6EDF3))),
                subtitle: Text(
                    n.createdAt.toLocal().toString().substring(0, 16),
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF8B98A5))),
                trailing: IconButton(
                  icon: const Icon(CupertinoIcons.trash,
                      size: 16, color: Colors.redAccent),
                  onPressed: () => vm.deleteNote(n),
                ),
              )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 7: Startup
  // ---------------------------------------------------------------------------
  Widget _buildStartupTab(CatViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.device_phone_portrait,
                      color: Color(0xFF4ADE80), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'iOS Home Screen & Desktop Overlay',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Bring the cat outside the app onto your iOS device:',
                style: TextStyle(fontSize: 12, color: Color(0xFFE6EDF3)),
              ),
              const SizedBox(height: 8),
              _buildFeatureBullet(
                CupertinoIcons.square_stack_3d_up,
                'iOS Home Screen Widget',
                'Add FocusCat WidgetKit companion to your iPhone Home Screen and Lock Screen.',
              ),
              const SizedBox(height: 6),
              _buildFeatureBullet(
                CupertinoIcons.bell_fill,
                'Live Activities & Dynamic Island',
                'Keep the animated cat live in the Dynamic Island while you browse other apps.',
              ),
              const SizedBox(height: 6),
              _buildFeatureBullet(
                CupertinoIcons.arrow_up_right_square,
                'Picture-in-Picture Floating Mode',
                'Float the animated cat over iOS apps and your Home Screen.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBullet(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF22D3EE)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE6EDF3),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B98A5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 8: About
  // ---------------------------------------------------------------------------
  Widget _buildAboutTab(CatViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FocusCat v3.0.0',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4ADE80))),
              SizedBox(height: 6),
              Text(
                'A desktop & mobile companion you can talk to. Free, privacy-preserving, and built for makers.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF8B98A5)),
              ),
              SizedBox(height: 12),
              Text('// © 2026 gokul.builds — built for the maker community',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Color(0xFF6B7A8A))),
            ],
          ),
        ),
      ],
    );
  }
}
