// lib/views/settings_sheet.dart
// iOS-native modal bottom sheet for settings, notes, reminders, and watchlist.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/cat_viewmodel.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) {
        return _SettingsSheetContent(scrollController: controller);
      },
    );
  }
}

class _SettingsSheetContent extends StatefulWidget {
  final ScrollController scrollController;
  const _SettingsSheetContent({required this.scrollController});

  @override
  State<_SettingsSheetContent> createState() => _SettingsSheetContentState();
}

class _SettingsSheetContentState extends State<_SettingsSheetContent> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<CatViewModel>().userName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatViewModel>();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141924),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // iOS Grab Pill
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          Row(
            children: [
              const Icon(
                CupertinoIcons.paw_solid,
                size: 20,
                color: Color(0xFF4ADE80),
              ),
              const SizedBox(width: 8),
              const Text(
                'FocusCat Settings',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE6EDF3),
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Color(0xFF4ADE80),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name field (iOS-styled CupertinoTextField)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1017),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF243040)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Companion Greeting Name',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF9AA8B4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Color(0xFFEEF1F6),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Enter your name…',
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (val) {
                    HapticFeedback.selectionClick();
                    vm.setUserName(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // iOS Toggles Section
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0C1017),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF243040)),
            ),
            child: Column(
              children: [
                // Chase finger toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.hand_point_right_fill,
                          size: 18, color: Color(0xFF4ADE80)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Chase finger when dragged',
                          style: TextStyle(fontSize: 13.5, color: Color(0xFFE6EDF3)),
                        ),
                      ),
                      CupertinoSwitch(
                        value: vm.chaseFingerEnabled,
                        activeTrackColor: const Color(0xFF4ADE80),
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          vm.setChaseFingerEnabled(v);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 42, color: Color(0xFF1E2836)),

                // Type along toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.keyboard,
                          size: 18, color: Color(0xFF22D3EE)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Type along on tiny keyboard',
                          style: TextStyle(fontSize: 13.5, color: Color(0xFFE6EDF3)),
                        ),
                      ),
                      CupertinoSwitch(
                        value: vm.typeAlongEnabled,
                        activeTrackColor: const Color(0xFF4ADE80),
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          vm.setTypeAlongEnabled(v);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 42, color: Color(0xFF1E2836)),

                // Hourly water reminder toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.drop_fill,
                          size: 18, color: Colors.lightBlueAccent),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hourly water reminder',
                              style: TextStyle(fontSize: 13.5, color: Color(0xFFE6EDF3)),
                            ),
                            Text(
                              'FocusCat pushes notifications to hydrate.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF9AA8B4)),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: vm.waterReminderEnabled,
                        activeTrackColor: const Color(0xFF4ADE80),
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          vm.setWaterReminderEnabled(v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Watched sites section
          const Text(
            'Watched Sites & Daily Limits',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE6EDF3),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0C1017),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF243040)),
            ),
            child: Column(
              children: vm.watchedSites.asMap().entries.map((entry) {
                final idx = entry.key;
                final rule = entry.value;
                return Column(
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      title: Text(
                        rule.domain,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                      subtitle: Text(
                        'Limit: ${rule.dailyMinutes} min · Remaining today: ${rule.remainingSeconds}s',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9AA8B4)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(CupertinoIcons.minus_circle,
                                size: 20, color: Colors.orangeAccent),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              vm.updateWatchedSiteMinutes(rule, -5);
                            },
                          ),
                          IconButton(
                            icon: const Icon(CupertinoIcons.plus_circle,
                                size: 20, color: Color(0xFF4ADE80)),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              vm.updateWatchedSiteMinutes(rule, 5);
                            },
                          ),
                        ],
                      ),
                    ),
                    if (idx < vm.watchedSites.length - 1)
                      const Divider(height: 1, indent: 14, color: Color(0xFF1E2836)),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Notes section
          Text(
            'Saved Notes (${vm.notes.length})',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE6EDF3),
            ),
          ),
          const SizedBox(height: 8),
          if (vm.notes.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1017),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF243040)),
              ),
              child: const Text(
                'No notes yet. Double-tap the cat, type anything, and hit Enter!',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0C1017),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF243040)),
              ),
              child: Column(
                children: vm.notes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final n = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        title: Text(
                          n.text,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFE6EDF3)),
                        ),
                        subtitle: Text(
                          n.createdAt.toLocal().toString().substring(0, 16),
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF9AA8B4)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash,
                              size: 16, color: Colors.redAccent),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            vm.deleteNote(n);
                          },
                        ),
                      ),
                      if (idx < vm.notes.length - 1)
                        const Divider(height: 1, indent: 14, color: Color(0xFF1E2836)),
                    ],
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
