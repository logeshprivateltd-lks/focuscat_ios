// lib/widgets/playground_card.dart
// Interactive pose and coat selector sandbox card directly matching https://gokulbuilds.com/focuscat/#poses

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/cat_models.dart';
import '../viewmodels/cat_viewmodel.dart';

class PlaygroundCard extends StatelessWidget {
  const PlaygroundCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatViewModel>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1114),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C2630)),
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
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4ADE80),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'try it yourself — the real FocusCat rig',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4ADE80),
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              // Test Swat button
              InkWell(
                onTap: () {
                  final rule = vm.getActiveWatchedRule() ??
                      vm.watchedSites.first;
                  vm.walkAndSwatActiveTab(rule);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '⚡ Test Swat',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pose selection chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CatPose.values.map((p) {
                final selected = vm.pose == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      String? bubble;
                      switch (p) {
                        case CatPose.sit:
                          bubble = 'Sitting calmly. 🐾';
                          break;
                        case CatPose.walk:
                          bubble = 'On patrol! Roaming the floor.';
                          break;
                        case CatPose.sleep:
                          bubble = 'Zzz... taking a cozy nap. 😴';
                          break;
                        case CatPose.pat:
                          bubble = 'Purrrrr... ♥';
                          break;
                        case CatPose.greet:
                          bubble = 'Hi there! Ready to focus?';
                          break;
                        case CatPose.bored:
                          bubble = 'Sigh... nothing to swat.';
                          break;
                        case CatPose.angry:
                          bubble = 'Hiss! Stay on task! 😾';
                          break;
                        case CatPose.confront:
                          bubble = 'Target tab locked...';
                          break;
                      }
                      vm.setPose(p, bubble);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF151D24),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF24303E),
                        ),
                      ),
                      child: Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF04120A)
                              : const Color(0xFF9AA8B4),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Coat color selection buttons with color swatches
          Row(
            children: [
              Text(
                'coat: ',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              ...CatColorPalette.values.map((c) {
                final selected = vm.catColor == c;
                Color swatchColor = c.fur;
                Color borderColor = c == CatColorPalette.white
                    ? Colors.white54
                    : (c == CatColorPalette.black
                        ? const Color(0xFFFFCE7A)
                        : const Color(0xFFD9A66B));

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      vm.setCatColor(c);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF222B35)
                            : const Color(0xFF141920),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF24303E),
                          width: selected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: swatchColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor, width: 1),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.normal,
                              color: selected
                                  ? const Color(0xFFE6EDF3)
                                  : const Color(0xFF8B98A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
