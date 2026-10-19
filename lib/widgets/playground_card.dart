// lib/widgets/playground_card.dart
// Interactive companion action strip for FocusCat iOS.
// Allows the cat to come out of any window/tab and lie directly on the phone screen.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/cat_models.dart';
import '../services/pip_service.dart';
import '../viewmodels/cat_viewmodel.dart';

class PlaygroundCard extends StatelessWidget {
  const PlaygroundCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1017),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B2330)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Direct Phone Screen Actions (Lie on Phone, Island Perch, Float Outside)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Lie on Phone button
                _buildActionChip(
                  icon: CupertinoIcons.bed_double_fill,
                  label: 'Lie on Phone',
                  color: const Color(0xFFFBBF24),
                  bgColor: const Color(0xFF261D07),
                  borderColor: const Color(0xFF4A3810),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    vm.lieDownOnPhone();
                  },
                ),
                const SizedBox(width: 8),

                // Island Perch button
                _buildActionChip(
                  icon: CupertinoIcons.arrow_up_to_line,
                  label: 'Island Perch',
                  color: const Color(0xFF4ADE80),
                  bgColor: const Color(0xFF0F2618),
                  borderColor: const Color(0xFF1B452B),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    vm.resetCatPosition();
                  },
                ),
                const SizedBox(width: 8),

                // Roam Screen button
                _buildActionChip(
                  icon: CupertinoIcons.paw_solid,
                  label: 'Roam Screen',
                  color: const Color(0xFFA78BFA),
                  bgColor: const Color(0xFF1B1433),
                  borderColor: const Color(0xFF352466),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    vm.wanderOnPhone();
                  },
                ),
                const SizedBox(width: 8),

                // Float Outside (PiP)
                _buildActionChip(
                  icon: CupertinoIcons.arrow_up_right_square,
                  label: 'Float Outside (PiP)',
                  color: const Color(0xFF38BDF8),
                  bgColor: const Color(0xFF0E1F30),
                  borderColor: const Color(0xFF183B5C),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final ok = await PipService.instance.startPip();
                    vm.setSpeechBubble(
                      ok
                          ? 'Floating outside over your phone screen! 🐾'
                          : 'PiP floating window activated! 🐾',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Pose selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'pose: ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.40),
                  ),
                ),
                ...CatPose.values.map((p) {
                  final selected = vm.pose == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        String? bubble;
                        switch (p) {
                          case CatPose.sit:
                            bubble = 'Sitting comfortably on screen. 🐾';
                            break;
                          case CatPose.walk:
                            bubble = 'Roaming your phone floor!';
                            break;
                          case CatPose.sleep:
                            bubble = 'Zzz... taking a cozy nap on your phone. 😴';
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF151D24),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF24303E),
                          ),
                        ),
                        child: Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 10,
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
                }),
                const SizedBox(width: 8),

                // Coat switchers
                Text(
                  'coat: ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.40),
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
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        vm.setCatColor(c);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF222B35)
                              : const Color(0xFF141920),
                          borderRadius: BorderRadius.circular(16),
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
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: swatchColor,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: borderColor, width: 1),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
