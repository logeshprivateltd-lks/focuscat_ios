// test/widget_test.dart
// Basic unit and smoke tests for FocusCat models and logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:focuscat_ios/models/cat_models.dart';

void main() {
  group('FocusCat Models Test', () {
    test('WatchedSiteRule calculation test', () {
      final rule = WatchedSiteRule(
        domain: 'youtube.com',
        dailyMinutes: 30,
        secondsUsedToday: 600,
      );

      expect(rule.totalAllowedSeconds, 1800);
      expect(rule.remainingSeconds, 1200);

      final updated = rule.copyWith(secondsUsedToday: 1800);
      expect(updated.remainingSeconds, 0);
    });

    test('CatNote serialization and deserialization test', () {
      final now = DateTime.now();
      final note = CatNote(
        id: 'test-note-1',
        text: 'Finish Codemagic setup',
        createdAt: now,
      );

      final json = note.toJson();
      final recovered = CatNote.fromJson(json);

      expect(recovered.id, 'test-note-1');
      expect(recovered.text, 'Finish Codemagic setup');
      expect(recovered.createdAt.toIso8601String(), now.toIso8601String());
    });

    test('CatReminder serialization and deserialization test', () {
      final reminder = CatReminder(
        id: 'rem-1',
        title: 'Drink Water',
        timeLabel: '14:00',
      );

      final json = reminder.toJson();
      final recovered = CatReminder.fromJson(json);

      expect(recovered.id, 'rem-1');
      expect(recovered.title, 'Drink Water');
      expect(recovered.timeLabel, '14:00');
    });
  });
}
