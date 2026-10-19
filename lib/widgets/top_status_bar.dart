// lib/widgets/top_status_bar.dart
// iOS native Status bar + focus timer + CupertinoActionSheet Tray menu.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/cat_viewmodel.dart';
import '../views/main_settings_window.dart';

class TopStatusBar extends StatelessWidget {
  const TopStatusBar({super.key});

  void _showTrayActionSheet(BuildContext context, CatViewModel vm) {
    HapticFeedback.selectionClick();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: const Text(
          'FocusCat Tray Menu',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        message: Text(
          vm.isPatrolling
              ? 'Cat is on patrol watching distracting tabs 🐾'
              : 'Cat is currently snoozing 😴',
          style: const TextStyle(fontSize: 13),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              MainSettingsWindow.show(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.settings, size: 18),
                const SizedBox(width: 8),
                Text('Settings & Notes (${vm.notes.length})…'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.selectionClick();
              vm.togglePatrol();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  vm.isPatrolling
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  size: 18,
                  color: vm.isPatrolling
                      ? const Color(0xFF4ADE80)
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(vm.isPatrolling ? 'On patrol (Active)' : 'Resume patrol'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
              vm.snooze30();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.moon_zzz, size: 18),
                SizedBox(width: 8),
                Text('Snooze 30m'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
              vm.toggleHidden();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  vm.isHidden
                      ? CupertinoIcons.eye
                      : CupertinoIcons.eye_slash,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(vm.isHidden ? 'Show the cat' : 'Hide the cat'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatViewModel>();

    return Row(
      children: [
        // Status pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF141924),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2C3646)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: vm.isPatrolling
                      ? const Color(0xFF4ADE80)
                      : Colors.orangeAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (vm.isPatrolling
                              ? const Color(0xFF4ADE80)
                              : Colors.orangeAccent)
                          .withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                vm.isPatrolling ? 'On patrol' : 'Snoozed',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE6EDF3),
                ),
              ),
              if (vm.focusSecondsRemaining > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '· 🍅 ${vm.formatTime(vm.focusSecondsRemaining)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFBBC24),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Spacer(),

        // iOS Tray Action Sheet Trigger
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showTrayActionSheet(context, vm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF141924),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2C3646)),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.paw_solid,
                  size: 14,
                  color: Color(0xFF4ADE80),
                ),
                SizedBox(width: 6),
                Text(
                  'Tray',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE6EDF3),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 11,
                  color: Color(0xFF9AA8B4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
