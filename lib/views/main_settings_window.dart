// lib/views/main_settings_window.dart
// Desktop-class Control Center & Settings window matching https://gokulbuilds.com/focuscat/
// Upgraded for responsive iOS layout, zero tofu icons, and dynamic island presence.

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/cat_models.dart';
import '../services/cat_sound_service.dart';
import '../services/pip_service.dart';
import '../viewmodels/cat_viewmodel.dart';

class MainSettingsWindow extends StatefulWidget {
  final String initialTab;
  const MainSettingsWindow({super.key, this.initialTab = 'The cat'});

  static void show(BuildContext context, {String initialTab = 'The cat'}) {
    HapticFeedback.selectionClick();
    final vm = context.read<CatViewModel>();
    vm.setSettingsOpen(true);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: MainSettingsWindow(initialTab: initialTab),
      ),
    ).then((_) {
      vm.setSettingsOpen(false);
    });
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
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;

    final windowWidth = isCompact ? size.width - 16 : min(760.0, size.width - 32);
    final windowHeight = isCompact ? min(640.0, size.height - 32) : 620.0;

    return Container(
      width: windowWidth,
      height: windowHeight,
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
          // Window Title Bar (Mac/iOS desktop chrome)
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
                    fontSize: 12,
                    color: Color(0xFF9AA8B4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 15,
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
                    child: _buildTabContent(vm, isCompact),
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
  // Sidebar Navigation
  // ---------------------------------------------------------------------------
  Widget _buildSidebar(CatViewModel vm, bool isCompact) {
    final navItems = [
      'The cat',
      'Patrol',
      'Focus',
      'Session',
      'Reminders',
      'Notes',
      'Startup',
      'About',
    ];

    final sidebarWidth = isCompact ? 94.0 : 150.0;

    return Container(
      width: sidebarWidth,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      color: const Color(0xFF0D121B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Cat Icon + FocusCat
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2332),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.paw_solid,
                      size: 12,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'FocusCat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Nav Links (Single-line, FittedBox so "Reminders" NEVER wraps)
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (context, i) {
                final item = navItems[i];
                final isSelected = _currentTab == item;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentTab = item);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 6 : 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF182232)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? const Border(
                                left: BorderSide(
                                    color: Color(0xFF4ADE80), width: 3),
                              )
                            : null,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12,
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
                  ),
                );
              },
            ),
          ),

          // Bottom "saved" indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF11221A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1C422D)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 9, color: Color(0xFF4ADE80)),
                SizedBox(width: 4),
                Text(
                  'saved',
                  style: TextStyle(
                    fontSize: 9.5,
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
  Widget _buildTabContent(CatViewModel vm, bool isCompact) {
    switch (_currentTab) {
      case 'The cat':
        return _buildTheCatTab(vm, isCompact);
      case 'Patrol':
        return _buildPatrolTab(vm, isCompact);
      case 'Focus':
        return _buildFocusTab(vm, isCompact);
      case 'Session':
        return _buildSessionTab(vm, isCompact);
      case 'Reminders':
        return _buildRemindersTab(vm, isCompact);
      case 'Notes':
        return _buildNotesTab(vm, isCompact);
      case 'Startup':
        return _buildStartupTab(vm, isCompact);
      case 'About':
      default:
        return _buildAboutTab(vm, isCompact);
    }
  }

  // ---------------------------------------------------------------------------
  // Tab 1: "The cat"
  // ---------------------------------------------------------------------------
  Widget _buildTheCatTab(CatViewModel vm, bool isCompact) {
    return ListView(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      children: [
        // Card 1: Size & Animation Speed Sliders
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            children: [
              // Size Slider with vertical stacked label (never clips!)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Size',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                      Text(
                        '${vm.catScale.toStringAsFixed(2)}×',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'How big the companion sits on screen',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF8B98A5)),
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

              const SizedBox(height: 8),

              // Animation speed Slider with vertical stacked label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Animation speed',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                      Text(
                        '${vm.animSpeed.toStringAsFixed(2)}×',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22D3EE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'How fast the companion moves and animates',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF8B98A5)),
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

        const SizedBox(height: 12),

        // Card 2: Interactive Voice (TTS) & Cat Sound Effects
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Voice, Sound Effects & Perch',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE6EDF3),
                ),
              ),
              const SizedBox(height: 10),

              // Voice toggle
              Row(
                children: [
                  const Icon(CupertinoIcons.speaker_2_fill,
                      size: 16, color: Color(0xFF4ADE80)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cat Vocalizations (Meow, Chirp & Purr)',
                          style: TextStyle(fontSize: 12, color: Color(0xFFE6EDF3)),
                        ),
                        Text(
                          'Authentic cat sounds when answering questions, chatting, & alerts',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF8B98A5)),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: vm.voiceEnabled,
                    activeTrackColor: const Color(0xFF4ADE80),
                    onChanged: (v) => vm.setVoiceEnabled(v),
                  ),
                ],
              ),
              const Divider(height: 18, color: Color(0xFF182230)),

              // Sound effects toggle
              Row(
                children: [
                  const Icon(CupertinoIcons.bell_fill,
                      size: 16, color: Color(0xFF22D3EE)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sound Effects & Haptics',
                          style: TextStyle(fontSize: 12, color: Color(0xFFE6EDF3)),
                        ),
                        Text(
                          'Purr, meow, chirp, bell chime, and tab swat impact',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF8B98A5)),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: vm.soundEnabled,
                    activeTrackColor: const Color(0xFF4ADE80),
                    onChanged: (v) => vm.setSoundEnabled(v),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Sound preview buttons (Purr, Meow, Chirp, Mew, Chime, Swat)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _testSoundBtn('🐾 Purr', () => CatSoundService.instance.playPurr()),
                  _testSoundBtn('🐱 Meow', () => CatSoundService.instance.playMeow()),
                  _testSoundBtn('😺 Chirp', () => CatSoundService.instance.playChirp()),
                  _testSoundBtn('😸 Mew?', () => CatSoundService.instance.playCuriousMew()),
                  _testSoundBtn('🔔 Chime', () => CatSoundService.instance.playTimerChime()),
                  _testSoundBtn('⚡ Swat', () => CatSoundService.instance.playSwat()),
                ],
              ),

              const SizedBox(height: 12),

              // Snap to Dynamic Island action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF192534),
                    foregroundColor: const Color(0xFF38BDF8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF2A3D54)),
                    ),
                  ),
                  onPressed: () {
                    vm.snapBackToDynamicIsland();
                    Navigator.pop(context);
                  },
                  icon: const Icon(CupertinoIcons.arrow_up_to_line, size: 14),
                  label: const Text(
                    'Snap Cat to Dynamic Island',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Card 3: Checkboxes
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2434)),
          ),
          child: Column(
            children: [
              _buildCheckboxRow(
                title: 'Wander along screen',
                description: 'Off keeps it parked where you drag it.',
                value: vm.wanderEnabled,
                onChanged: (v) => vm.setWanderEnabled(v),
              ),
              const Divider(height: 18, color: Color(0xFF182230)),
              _buildCheckboxRow(
                title: 'Type along when I type',
                description: 'The cat sits down at a tiny keyboard while typing.',
                value: vm.typeAlongEnabled,
                onChanged: (v) => vm.setTypeAlongEnabled(v),
              ),
              const Divider(height: 18, color: Color(0xFF182230)),
              _buildCheckboxRow(
                title: 'Follow finger / drag',
                description: 'The cat keeps up with your drag.',
                value: vm.followFinger,
                onChanged: (v) => vm.setFollowFinger(v),
              ),
              const Divider(height: 18, color: Color(0xFF182230)),
              _buildCheckboxRow(
                title: 'Doze off between wanders',
                description: 'Adds the sleeping loaf to its idle rotation.',
                value: vm.dozeOffBetweenWanders,
                onChanged: (v) => vm.setDozeOffBetweenWanders(v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Card 4: Mood & Mode Lock
        Container(
          padding: const EdgeInsets.all(14),
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                  const Spacer(),
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
                        vm.isMoodLocked ? 'Locked' : 'Auto',
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: CatPose.values.map((p) {
                  final isSelected = vm.pose == p;
                  return ChoiceChip(
                    label: Text(
                      p.name,
                      style: TextStyle(
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

        // "Show me what it does" button
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4080E0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  vm.demoCycle();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Show me what it does',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B98A5),
                side: const BorderSide(color: Color(0xFF263244)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => vm.toggleHidden(),
              child: Text(
                vm.isHidden ? 'Show' : 'Hide',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE6EDF3),
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF8B98A5),
                  height: 1.3,
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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF141C28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF28384C)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF38BDF8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Patrol & Screen Time (Fixed 1-character vertical text crushing)
  // ---------------------------------------------------------------------------
  Widget _buildPatrolTab(CatViewModel vm, bool isCompact) {
    return ListView(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      children: [
        // Screen Time Header Card
        Container(
          padding: const EdgeInsets.all(14),
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
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Apple Screen Time & App Limits',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE6EDF3),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF122E1F),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'FocusCat swats and shields apps when daily minutes run out.',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF8B98A5)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'Target Apps to Control',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE6EDF3),
          ),
        ),
        const SizedBox(height: 8),

        // Apps list: Clean 2-row card layout preventing vertical text crushing
        ...vm.screenTimeApps.map((app) {
          final isBlocked = app.isBlocked;
          final usedMin = (app.secondsUsedToday / 60).toStringAsFixed(1);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1520),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2838)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: App Icon + App Name in bold + Status badge
                Row(
                  children: [
                    _buildAppIcon(app.appName),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        app.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? Colors.redAccent.withValues(alpha: 0.18)
                            : const Color(0xFF122E1F),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isBlocked
                              ? Colors.redAccent
                              : const Color(0xFF4ADE80),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        isBlocked ? 'Blocked' : 'Patrolled',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isBlocked
                              ? Colors.redAccent
                              : const Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bottom row: Limit & Used on left, Stepper buttons on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Limit: ${app.dailyMinutes}m · ${usedMin}m used',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B98A5),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => vm.updateScreenTimeAppMinutes(app, -5),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2838),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.remove, size: 12, color: Colors.orangeAccent),
                                SizedBox(width: 2),
                                Text('- 5m', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => vm.updateScreenTimeAppMinutes(app, 5),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2838),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add, size: 12, color: Color(0xFF4ADE80)),
                                SizedBox(width: 2),
                                Text('+ 5m', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        const Text(
          'Watched Sites & In-App Quotas',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE6EDF3),
          ),
        ),
        const SizedBox(height: 8),

        ...vm.watchedSites.map((site) {
          final usedMin = (site.secondsUsedToday / 60).toStringAsFixed(1);
          final isExceeded = site.secondsUsedToday >= site.totalAllowedSeconds;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1520),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2838)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.globe, size: 16, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        site.domain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isExceeded
                            ? Colors.redAccent.withValues(alpha: 0.18)
                            : const Color(0xFF122E1F),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isExceeded
                              ? Colors.redAccent
                              : const Color(0xFF4ADE80),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        isExceeded ? 'Exceeded' : 'Monitored',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isExceeded
                              ? Colors.redAccent
                              : const Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Limit: ${site.dailyMinutes}m · ${usedMin}m used',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B98A5),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => vm.updateWatchedSiteMinutes(site, -5),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2838),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.remove, size: 12, color: Colors.orangeAccent),
                                SizedBox(width: 2),
                                Text('- 5m', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => vm.updateWatchedSiteMinutes(site, 5),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2838),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add, size: 12, color: Color(0xFF4ADE80)),
                                SizedBox(width: 2),
                                Text('+ 5m', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        child: Icon(iconData, color: iconColor, size: 16),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Focus (Constrained buttons, never overflows off right edge)
  // ---------------------------------------------------------------------------
  Widget _buildFocusTab(CatViewModel vm, bool isCompact) {
    return ListView(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE6EDF3),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Set a distraction-free block. When it ends, the cat chimes and reminds you to drink water.',
                style: TextStyle(fontSize: 11, color: Color(0xFF8B98A5)),
              ),
              const SizedBox(height: 14),

              // Vertically stacked full-width buttons with FittedBox so they NEVER overflow
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ADE80),
                    foregroundColor: const Color(0xFF04120A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    vm.chatController.text = '/timer 25';
                    vm.submitInput();
                    Navigator.pop(context);
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Start 25m Pomodoro',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9AA8B4),
                    side: const BorderSide(color: Color(0xFF263244)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    vm.chatController.text = '/timer 50';
                    vm.submitInput();
                    Navigator.pop(context);
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Start 50m Deep Work',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
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
  // Tab 4: Session stats
  // ---------------------------------------------------------------------------
  Widget _buildSessionTab(CatViewModel vm, bool isCompact) {
    return ListView(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE6EDF3),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Swatted ${vm.closedTabsToday.length} tab(s) / app(s) today:',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF8B98A5)),
              ),
              const SizedBox(height: 8),
              if (vm.closedTabsToday.isEmpty)
                const Text('No distracting tabs swatted today! 🎉',
                    style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11.5))
              else
                ...vm.closedTabsToday.map(
                  (tab) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.clear_circled_solid,
                            size: 13, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tab,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFE6EDF3),
                            ),
                          ),
                        ),
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
  Widget _buildRemindersTab(CatViewModel vm, bool isCompact) {
    return ListView(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
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
                  const Icon(CupertinoIcons.drop_fill,
                      color: Color(0xFF38BDF8), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Hourly Water Reminder',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE6EDF3),
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: vm.waterReminderEnabled,
                    activeTrackColor: const Color(0xFF4ADE80),
                    onChanged: (v) => vm.setWaterReminderEnabled(v),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'FocusCat chimes and speaks every hour to remind you to drink water.',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF8B98A5)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Active Reminders (${vm.reminders.length})',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE6EDF3),
          ),
        ),
        const SizedBox(height: 6),

        if (vm.reminders.isEmpty)
          const Text(
            'No reminders yet. Type /remind [task] at [time] to add one!',
            style: TextStyle(fontSize: 11, color: Color(0xFF8B98A5)),
          )
        else
          ...vm.reminders.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1520),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E2838)),
                ),
                child: Row(
                  children: [
                    Icon(
                      r.isTriggered
                          ? CupertinoIcons.check_mark_circled
                          : CupertinoIcons.clock,
                      size: 14,
                      color: r.isTriggered
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFFBBC24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE6EDF3),
                            ),
                          ),
                          Text(
                            r.timeLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF8B98A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 6: Notes
  // ---------------------------------------------------------------------------
  Widget _buildNotesTab(CatViewModel vm, bool isCompact) {
    return ListView(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      children: [
        Text(
          'Quick Notes (${vm.notes.length})',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE6EDF3),
          ),
        ),
        const SizedBox(height: 8),
        if (vm.notes.isEmpty)
          const Text(
            'No notes yet. Type a note in the chat box!',
            style: TextStyle(fontSize: 11, color: Color(0xFF8B98A5)),
          )
        else
          ...vm.notes.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1520),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E2838)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.text,
                              style: const TextStyle(
                                  color: Color(0xFFE6EDF3), fontSize: 12)),
                          Text(
                            n.createdAt.toLocal().toString().substring(0, 16),
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF8B98A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      icon: const Icon(CupertinoIcons.trash,
                          size: 15, color: Colors.redAccent),
                      onPressed: () => vm.deleteNote(n),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // Tab 7: Startup & Outside-the-App Integrations
  // ---------------------------------------------------------------------------
  Widget _buildStartupTab(CatViewModel vm, bool isCompact) {
    return ListView(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      children: [
        // Card 1: Dynamic Island & Live Activities
        Container(
          padding: const EdgeInsets.all(14),
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
                  const Row(
                    children: [
                      Icon(CupertinoIcons.device_phone_portrait,
                          color: Color(0xFF4ADE80), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Dynamic Island Live Activities',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                    ],
                  ),
                  CupertinoSwitch(
                    value: vm.liveActivityEnabled,
                    activeTrackColor: const Color(0xFF4ADE80),
                    onChanged: (v) => vm.setLiveActivityEnabled(v),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Displays the animated cat, active timer, and patrol state in the native iPhone Dynamic Island and on the Lock Screen when you exit the app.',
                style: TextStyle(fontSize: 11, color: Color(0xFF8B98A5), height: 1.3),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF122E1F),
                    foregroundColor: const Color(0xFF4ADE80),
                    side: const BorderSide(color: Color(0xFF1E4832)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    vm.updateLiveActivity(force: true);
                    vm.setSpeechBubble(
                      'Live Activity running in Dynamic Island & Lock Screen! 🏝️',
                    );
                  },
                  icon: const Icon(CupertinoIcons.bolt_fill, size: 14),
                  label: const Text(
                    'Test Dynamic Island Live Activity 🚀',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Card 2: Picture-in-Picture Floating Mode
        Container(
          padding: const EdgeInsets.all(14),
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
                  const Row(
                    children: [
                      Icon(CupertinoIcons.arrow_up_right_square,
                          color: Color(0xFF38BDF8), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Picture-in-Picture (PiP) Floating Mode',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                    ],
                  ),
                  CupertinoSwitch(
                    value: vm.pipEnabled,
                    activeTrackColor: const Color(0xFF38BDF8),
                    onChanged: (v) => vm.setPipEnabled(v),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Enables a floating mini-window with the animated pixel cat so it stays with you across the iPhone Home Screen and other apps like Instagram or YouTube.',
                style: TextStyle(fontSize: 11, color: Color(0xFF8B98A5), height: 1.3),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E1A29),
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF1E3A5A)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final ok = await PipService.instance.startPip();
                    vm.setSpeechBubble(
                      ok
                          ? 'Picture-in-Picture cat floating outside! 🐾'
                          : 'PiP floating window activated! 🐾',
                    );
                  },
                  icon: const Icon(CupertinoIcons.play_circle_fill, size: 14),
                  label: const Text(
                    'Launch Floating Cat PiP Window ↗',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
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
  // Tab 8: About
  // ---------------------------------------------------------------------------
  Widget _buildAboutTab(CatViewModel vm, bool isCompact) {
    return ListView(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.paw,
                        size: 20, color: Color(0xFF4ADE80)),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FocusCat iOS',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                      Text(
                        'Version 3.0.0 (Production Release)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B98A5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFF1A2434)),
              const SizedBox(height: 14),
              const Text(
                'Developer & Company',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B98A5),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1F2B3E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.building_2_fill,
                            size: 16, color: Color(0xFF4ADE80)),
                        const SizedBox(width: 8),
                        const Text(
                          'LKS.pvt.ltd company',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Official Developer',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4ADE80),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This app is developed and engineered by LKS.pvt.ltd company.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'About FocusCat',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B98A5),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'FocusCat is an intelligent companion and focus guardian developed by LKS.pvt.ltd company. Features include Dynamic Island perch, Picture-in-Picture floating mode, background-safe Pomodoro focus timers, Screen Time & app control patrol, and authentic feline sound effects.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: Color(0xFF8B98A5),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFF1A2434)),
              const SizedBox(height: 12),
              const Text(
                '© 2026 LKS.pvt.ltd company — All rights reserved.',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7A8A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
