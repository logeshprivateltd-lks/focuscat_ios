// lib/widgets/chat_command_box.dart
// Chat/command input box matching the official FocusCat popup styling.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/cat_viewmodel.dart';

class ChatCommandBox extends StatelessWidget {
  const ChatCommandBox({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatViewModel>();

    return AnimatedSlide(
      offset: vm.isChatOpen ? Offset.zero : const Offset(0, 0.12),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: vm.isChatOpen ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        child: IgnorePointer(
          ignoring: !vm.isChatOpen,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141924),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2C3646)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.75),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick-chip row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: vm.quickChips.map((chip) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            vm.chatController.text = chip;
                            vm.submitInput();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2230),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFF334055)),
                            ),
                            child: Text(
                              chip,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF9AA8B4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Text field
                TextField(
                  controller: vm.chatController,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFFEEF1F6),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write a note, or ask me something…',
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0C1017),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF243040)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF243040)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF4ADE80)),
                    ),
                  ),
                  onChanged: vm.onTextChanged,
                  onSubmitted: (_) => vm.submitInput(),
                ),
                const SizedBox(height: 10),

                // Bottom action row
                Row(
                  children: [
                    Text(
                      'Enter saves a note',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.40),
                      ),
                    ),
                    const Spacer(),
                    _MiniBtn(
                      'Help',
                      onTap: () {
                        vm.chatController.text = 'help?';
                        vm.submitInput();
                      },
                    ),
                    const SizedBox(width: 8),
                    _MiniBtn(
                      'Send',
                      isPrimary: true,
                      onTap: () => vm.submitInput(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _MiniBtn(this.label, {required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF4ADE80)
              : const Color(0xFF1E2633),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF4ADE80)
                : const Color(0xFF334055),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isPrimary ? const Color(0xFF04120A) : const Color(0xFFE6EDF3),
          ),
        ),
      ),
    );
  }
}
