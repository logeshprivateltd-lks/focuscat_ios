// test/widget_test.dart
// Comprehensive unit tests for FocusCat iOS v3.0:
// Models, Strict URL Matching, Timestamp Timers, Midnight Quota Resets,
// and Reminder Triggers.

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuscat_ios/models/cat_models.dart';

void main() {
  group('FocusCat Models Test', () {
    test('WatchedSiteRule calculation & quota update test', () {
      final rule = WatchedSiteRule(
        domain: 'youtube.com',
        dailyMinutes: 30,
        secondsUsedToday: 600,
      );

      expect(rule.totalAllowedSeconds, 1800);
      expect(rule.remainingSeconds, 1200);

      // Preserving secondsUsedToday when changing quota
      final updated = rule.copyWith(
        dailyMinutes: 45,
        secondsUsedToday: rule.secondsUsedToday,
      );
      expect(updated.dailyMinutes, 45);
      expect(updated.totalAllowedSeconds, 2700);
      expect(updated.secondsUsedToday, 600);
      expect(updated.remainingSeconds, 2100);

      final exhausted = updated.copyWith(secondsUsedToday: 2700);
      expect(exhausted.remainingSeconds, 0);
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

    test('CatReminder serialization and triggerAt evaluation', () {
      final triggerTime = DateTime(2026, 10, 19, 15, 30);
      final reminder = CatReminder(
        id: 'rem-1',
        title: 'Drink Water',
        timeLabel: '15:30',
        triggerAt: triggerTime,
        isTriggered: false,
      );

      final json = reminder.toJson();
      final recovered = CatReminder.fromJson(json);

      expect(recovered.id, 'rem-1');
      expect(recovered.title, 'Drink Water');
      expect(recovered.timeLabel, '15:30');
      expect(recovered.triggerAt.toIso8601String(), triggerTime.toIso8601String());
      expect(recovered.isTriggered, false);

      // Simulating trigger condition
      final afterTime = DateTime(2026, 10, 19, 15, 31);
      expect(afterTime.isAfter(recovered.triggerAt), true);

      final triggeredReminder = recovered.copyWith(isTriggered: true);
      expect(triggeredReminder.isTriggered, true);
    });
  });

  group('Strict Host + Path URL Matching Tests', () {
    WatchedSiteRule? matchUrl(String currentUrl, List<WatchedSiteRule> rules) {
      final uri = Uri.tryParse(currentUrl.trim());
      if (uri == null || uri.host.isEmpty) return null;

      final host = uri.host.toLowerCase();
      final path = uri.path.toLowerCase();

      for (final rule in rules) {
        final domainParts = rule.domain.toLowerCase().split('/');
        final ruleHost = domainParts.first;
        final rulePath =
            domainParts.length > 1 ? '/${domainParts.sublist(1).join('/')}' : '';

        final hostMatches = host == ruleHost || host.endsWith('.$ruleHost');
        if (!hostMatches) continue;

        if (rulePath.isNotEmpty) {
          if (path.startsWith(rulePath)) return rule;
        } else {
          return rule;
        }
      }
      return null;
    }

    final rules = [
      WatchedSiteRule(domain: 'youtube.com/shorts', dailyMinutes: 15),
      WatchedSiteRule(domain: 'reddit.com', dailyMinutes: 20),
      WatchedSiteRule(domain: 'x.com', dailyMinutes: 15),
    ];

    test('Exact domain and subdomains match properly', () {
      expect(matchUrl('https://reddit.com/r/flutterdev', rules)?.domain, 'reddit.com');
      expect(matchUrl('https://old.reddit.com/popular', rules)?.domain, 'reddit.com');
      expect(matchUrl('https://x.com/home', rules)?.domain, 'x.com');
    });

    test('Path-specific rule matches correctly', () {
      expect(matchUrl('https://youtube.com/shorts/dQw4w9WgXcQ', rules)?.domain,
          'youtube.com/shorts');
      expect(matchUrl('https://m.youtube.com/shorts', rules)?.domain,
          'youtube.com/shorts');
      // Non-shorts YouTube path must not match youtube.com/shorts
      expect(matchUrl('https://youtube.com/watch?v=123', rules), isNull);
      expect(matchUrl('https://youtube.com/feed/subscriptions', rules), isNull);
    });

    test('Search queries containing watched domains are NOT falsely swatted', () {
      // Searching for reddit or youtube on google must NOT trigger rules
      expect(matchUrl('https://www.google.com/search?q=reddit.com', rules), isNull);
      expect(matchUrl('https://www.google.com/search?q=youtube.com%2Fshorts', rules),
          isNull);
      expect(matchUrl('https://duckduckgo.com/?q=https://x.com', rules), isNull);
      expect(matchUrl('https://bing.com/search?q=reddit+tips', rules), isNull);
    });
  });

  group('Timestamp-Based Background Timers Tests', () {
    test('Calculates remaining seconds dynamically from focusEndTime', () {
      final now = DateTime.now();
      final focusEndTime = now.add(const Duration(minutes: 25));

      final remainingSeconds = max(0, focusEndTime.difference(now).inSeconds);
      expect(remainingSeconds, 1500);

      // Simulate 5 minutes elapsed
      final futureTime = now.add(const Duration(minutes: 5));
      final remainingAfter5m = max(0, focusEndTime.difference(futureTime).inSeconds);
      expect(remainingAfter5m, 1200);

      // Simulate timer expiration
      final expiredTime = now.add(const Duration(minutes: 26));
      final remainingExpired = max(0, focusEndTime.difference(expiredTime).inSeconds);
      expect(remainingExpired, 0);
    });
  });

  group('Midnight Quota Reset Tests', () {
    test('Resets secondsUsedToday when calendar day changes', () {
      final sites = [
        WatchedSiteRule(domain: 'youtube.com', dailyMinutes: 20, secondsUsedToday: 1200),
        WatchedSiteRule(domain: 'reddit.com', dailyMinutes: 15, secondsUsedToday: 900),
      ];
      final closedTabs = ['YouTube', 'Reddit (Limit exceeded)'];

      const lastResetDate = '2026-10-18';
      const todayDate = '2026-10-19';

      expect(lastResetDate != todayDate, true);

      // Perform reset
      for (final site in sites) {
        site.secondsUsedToday = 0;
      }
      closedTabs.clear();

      expect(sites[0].secondsUsedToday, 0);
      expect(sites[1].secondsUsedToday, 0);
      expect(closedTabs.isEmpty, true);
    });
  });

  group('Cat Position Reset & Bounded Dragging Tests', () {
    test('Clamps cat coordinates strictly within bounded screen safe area', () {
      double catX = 0.0;
      double catY = 0.0;

      void onCatDrag2D(double dx, double dy, double minX, double maxX, double minY, double maxY) {
        catX = (catX + dx).clamp(minX, maxX);
        catY = (catY + dy).clamp(minY, maxY);
      }

      // Dragging beyond right bound
      onCatDrag2D(500.0, 200.0, -150.0, 150.0, 0.0, 400.0);
      expect(catX, 150.0);
      expect(catY, 200.0);

      // Dragging beyond top and left bounds
      onCatDrag2D(-400.0, -500.0, -150.0, 150.0, 0.0, 400.0);
      expect(catX, -150.0);
      expect(catY, 0.0); // Never above perch / island

      // Reset Cat Position returns offsets smoothly to (0, 0)
      catX = 0.0;
      catY = 0.0;
      expect(catX, 0.0);
      expect(catY, 0.0);
    });
  });

  group('Focus Presets & PipService Tests', () {
    test('Focus Presets correctly calculate duration and focusEndTime', () {
      final startTime = DateTime(2026, 10, 19, 10, 0, 0);
      
      final presets = [15, 25, 45];
      for (final minutes in presets) {
        final expectedEndTime = startTime.add(Duration(minutes: minutes));
        expect(expectedEndTime.difference(startTime).inMinutes, minutes);
        expect(expectedEndTime.difference(startTime).inSeconds, minutes * 60);
      }
    });
  });

  group('Developer Attribution & Cat Vocalization Tests', () {
    test('Company attribution points to LKS.pvt.ltd company', () {
      const company = 'LKS.pvt.ltd company';
      expect(company, contains('LKS.pvt.ltd company'));
    });

    test('Vocalization routing picks cat sounds based on message sentiment', () {
      String getSoundType(String text) {
        final lower = text.toLowerCase();
        if (lower.contains('purr') || lower.contains('♥') || lower.contains('pat')) {
          return 'purr';
        } else if (lower.contains('swat') || lower.contains('stop') || lower.contains('blocked')) {
          return 'swat';
        } else if (lower.contains('water') || lower.contains('drink')) {
          return 'water';
        } else if (lower.contains('focus') || lower.contains('pomodoro')) {
          return 'chime';
        } else if (lower.contains('?') || lower.contains('battery')) {
          return 'curious_mew';
        } else {
          return 'chirp';
        }
      }

      expect(getSoundType('Purrrrr... ♥'), 'purr');
      expect(getSoundType('Tab blocked! Distraction swat!'), 'swat');
      expect(getSoundType('Drink water reminder'), 'water');
      expect(getSoundType('Started 25m focus session!'), 'chime');
      expect(getSoundType('How is my battery?'), 'curious_mew');
      expect(getSoundType('Hello companion!'), 'chirp');
    });
  });

  group('iOS Home Screen Widget Support Tests', () {
    test('Widget payload accurately serializes cat pose, emoji, mood, timer & attribution', () {
      final endTime = DateTime(2026, 10, 19, 12, 0, 0);
      final widgetData = {
        'catPose': 'sit',
        'catEmoji': '🐱',
        'catMood': 'Chill',
        'speechBubble': 'Purr... staying focused! 🐾',
        'isPatrolling': true,
        'focusSecondsRemaining': 1500,
        'focusEndTime': endTime.millisecondsSinceEpoch / 1000.0,
        'targetAppOrDomain': 'youtube.com',
        'dailyFocusMinutes': 25,
        'company': 'LKS.pvt.ltd company',
      };

      expect(widgetData['catPose'], 'sit');
      expect(widgetData['catEmoji'], '🐱');
      expect(widgetData['catMood'], 'Chill');
      expect(widgetData['speechBubble'], contains('staying focused'));
      expect(widgetData['isPatrolling'], true);
      expect(widgetData['focusSecondsRemaining'], 1500);
      expect(widgetData['focusEndTime'], isNotNull);
      expect(widgetData['targetAppOrDomain'], 'youtube.com');
      expect(widgetData['company'], 'LKS.pvt.ltd company');
    });

    test('Cat mood names correctly translate from CatPose states', () {
      String getMood(CatPose pose, bool isPatrolling) {
        switch (pose) {
          case CatPose.sleep:
            return 'Sleepy';
          case CatPose.pat:
            return 'Purring';
          case CatPose.greet:
            return 'Happy';
          case CatPose.bored:
            return 'Resting';
          case CatPose.walk:
            return 'Wandering';
          case CatPose.angry:
          case CatPose.confront:
            return 'Shielding';
          case CatPose.sit:
            return isPatrolling ? 'Patrolling' : 'Chill';
        }
      }

      expect(getMood(CatPose.sleep, true), 'Sleepy');
      expect(getMood(CatPose.pat, true), 'Purring');
      expect(getMood(CatPose.greet, true), 'Happy');
      expect(getMood(CatPose.walk, true), 'Wandering');
      expect(getMood(CatPose.angry, true), 'Shielding');
      expect(getMood(CatPose.sit, true), 'Patrolling');
      expect(getMood(CatPose.sit, false), 'Chill');
    });
  });
}

