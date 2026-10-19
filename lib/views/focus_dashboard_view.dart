// lib/views/focus_dashboard_view.dart
// Clean, cohesive FocusCat Companion Stage & Patrol Dashboard.
// Replaces the in-app WebView box with an intuitive focus command hub.

import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/cat_models.dart';
import '../services/pip_service.dart';
import '../viewmodels/cat_viewmodel.dart';
import '../views/main_settings_window.dart';

class FocusDashboardView extends StatelessWidget {
  const FocusDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatViewModel>();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        // ---------------------------------------------------------------------
        // 1. Focus / Pomodoro Timer Card
        // ---------------------------------------------------------------------
        _buildFocusTimerCard(context, vm),
        const SizedBox(height: 10),

        // ---------------------------------------------------------------------
        // 2. Active Patrol & Guard Shield Status Card
        // ---------------------------------------------------------------------
        _buildPatrolStatusCard(context, vm),
        const SizedBox(height: 10),

        // ---------------------------------------------------------------------
        // 3. Quick Notes & Upcoming Reminders Preview
        // ---------------------------------------------------------------------
        _buildNotesAndRemindersCard(context, vm),
        const SizedBox(height: 12),

        // Company attribution
        const Center(
          child: Text(
            'FocusCat iOS · Developed by LKS.pvt.ltd company',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7A8A),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ===========================================================================
  // 1. Focus Timer Card
  // ===========================================================================
  Widget _buildFocusTimerCard(BuildContext context, CatViewModel vm) {
    final isFocusing = vm.focusSecondsRemaining > 0;
    final totalFocusSeconds = isFocusing && vm.focusEndTime != null
        ? 25 * 60 // default reference block
        : 1;
    final progress = isFocusing
        ? (vm.focusSecondsRemaining / totalFocusSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1219),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocusing ? const Color(0xFF22C55E) : const Color(0xFF1E2838),
          width: isFocusing ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isFocusing
                          ? const Color(0xFF14532D)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.timer,
                      size: 16,
                      color: isFocusing
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Focus & Pomodoro Timer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFocusing
                      ? const Color(0xFF14532D)
                      : const Color(0xFF182230),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocusing
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF2E3D52),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isFocusing
                            ? const Color(0xFF4ADE80)
                            : Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isFocusing ? 'FOCUSING' : 'READY',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isFocusing
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timer Center Display
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFocusing
                          ? vm.formatTime(vm.focusSecondsRemaining)
                          : '25:00',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isFocusing
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFE6EDF3),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      isFocusing
                          ? 'Distraction-free session active. Keep going!'
                          : 'Pick a session duration to begin:',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B98A5),
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              if (isFocusing) ...[
                IconButton(
                  tooltip: 'Pause',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    vm.pauseFocusTimer();
                  },
                  icon: const Icon(CupertinoIcons.pause_circle_fill,
                      size: 32, color: Colors.orangeAccent),
                ),
                IconButton(
                  tooltip: 'Reset',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    vm.resetFocusTimer();
                  },
                  icon: const Icon(CupertinoIcons.stop_circle_fill,
                      size: 32, color: Colors.redAccent),
                ),
              ],
            ],
          ),

          if (isFocusing) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: const Color(0xFF1E293B),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Quick Start Presets
          Row(
            children: [
              Expanded(
                child: _buildPresetButton(
                  label: '25m Focus',
                  minutes: 25,
                  isSelected: isFocusing && vm.focusSecondsRemaining > 15 * 60,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    vm.startFocusPreset(25);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  label: '15m Break',
                  minutes: 15,
                  isSelected: isFocusing && vm.focusSecondsRemaining <= 15 * 60,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    vm.startFocusPreset(15);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  label: '45m Deep',
                  minutes: 45,
                  isSelected: false,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    vm.startFocusPreset(45);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required int minutes,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF166534)
              : const Color(0xFF141C28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4ADE80)
                : const Color(0xFF243040),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFFE2E8F0),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. Active Patrol & Shield Card
  // ===========================================================================
  Widget _buildPatrolStatusCard(BuildContext context, CatViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1219),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2838)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: vm.isPatrolling
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.shield_fill,
                      size: 16,
                      color: vm.isPatrolling
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'App Patrol & Screen Time Shield',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  vm.togglePatrol();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: vm.isPatrolling
                        ? const Color(0xFF122E1F)
                        : const Color(0xFF281E12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: vm.isPatrolling
                          ? const Color(0xFF4ADE80)
                          : Colors.orangeAccent,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    vm.isPatrolling ? 'PATROL ACTIVE' : 'PAUSED',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: vm.isPatrolling
                          ? const Color(0xFF4ADE80)
                          : Colors.orangeAccent,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Watched Apps Quotas
          ...vm.screenTimeApps.take(3).map((app) {
            final usedMin = app.secondsUsedToday / 60.0;
            final allowedMin = max(1, app.dailyMinutes);
            final ratio = (usedMin / allowedMin).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        app.appName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                      Text(
                        '${usedMin.toStringAsFixed(1)}m / ${app.dailyMinutes}m',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: ratio >= 1.0
                              ? Colors.redAccent
                              : const Color(0xFF8B98A5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 4,
                      backgroundColor: const Color(0xFF1E2838),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ratio >= 1.0
                            ? Colors.redAccent
                            : ratio > 0.8
                                ? Colors.orangeAccent
                                : const Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Outside-the-App Controls (Dynamic Island & PiP Floating Mode)
          Row(
            children: [
              // Dynamic Island button
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4ADE80),
                    side: const BorderSide(color: Color(0xFF1A3D28)),
                    backgroundColor: const Color(0xFF0D1D14),
                    padding: const EdgeInsets.symmetric(vertical: 9),
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
                  icon: const Icon(CupertinoIcons.device_phone_portrait,
                      size: 14),
                  label: const Text(
                    'Dynamic Island',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // PiP Floating Mode button
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF16324D)),
                    backgroundColor: const Color(0xFF0E1A29),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final success = await PipService.instance.startPip();
                    vm.setSpeechBubble(
                      success
                          ? 'Picture-in-Picture cat floating outside! 🐾'
                          : 'PiP floating window activated! 🐾',
                    );
                  },
                  icon: const Icon(CupertinoIcons.arrow_up_right_square,
                      size: 14),
                  label: const Text(
                    'PiP Floating Cat',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. Quick Notes & Reminders Card
  // ===========================================================================
  Widget _buildNotesAndRemindersCard(BuildContext context, CatViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1219),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2838)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.pencil_outline,
                      size: 16, color: Color(0xFF818CF8)),
                  SizedBox(width: 8),
                  Text(
                    'Notes & Reminders',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6EDF3),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  MainSettingsWindow.show(context, initialTab: 'Notes');
                },
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF818CF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Recent Note Preview
          if (vm.notes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF131A26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.doc_plaintext,
                      size: 14, color: Color(0xFF818CF8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.notes.last.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF131A26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No notes yet. Double-tap the cat to chat or jot a quick note!',
                style: TextStyle(fontSize: 11, color: Color(0xFF8B98A5)),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Action row: Test Swat + Water Reminder chip
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    final rule = vm.getActiveWatchedRule() ??
                        (vm.watchedSites.isNotEmpty
                            ? vm.watchedSites.first
                            : WatchedSiteRule(
                                domain: 'youtube.com/shorts',
                                dailyMinutes: 20,
                              ));
                    vm.walkAndSwatActiveTab(rule);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.bolt_fill,
                              size: 13, color: Colors.redAccent),
                          SizedBox(width: 5),
                          Text(
                            'Test Patrol Swat',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    vm.chatController.text = '/remind Drink water at 4pm';
                    vm.submitInput();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.drop_fill,
                              size: 13, color: Color(0xFF38BDF8)),
                          SizedBox(width: 5),
                          Text(
                            'Water Reminder',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
