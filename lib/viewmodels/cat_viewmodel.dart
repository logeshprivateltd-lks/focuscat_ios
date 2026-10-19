// lib/viewmodels/cat_viewmodel.dart
// Central ChangeNotifier ViewModel for FocusCat iOS v3.0.
// Handles companion state, mood locking, 2D dragging, Screen Time app limits,
// timestamp-based background timers, midnight resets, and interactive voice/SFX.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/cat_models.dart';
import '../services/cat_sound_service.dart';
import '../services/live_activity_service.dart';
import '../services/notification_service.dart';
import '../services/persistence_service.dart';
import '../services/screen_time_service.dart';
import '../services/telemetry_service.dart';
import '../services/widget_service.dart';
import '../views/main_settings_window.dart';

class CatViewModel extends ChangeNotifier with WidgetsBindingObserver {
  // -------------------------------------------------------------------------
  // Services
  // -------------------------------------------------------------------------
  final PersistenceService _persistence = PersistenceService();
  final TelemetryService _telemetry = TelemetryService();
  final NotificationService _notifications = NotificationService();
  final CatSoundService _sound = CatSoundService.instance;
  final ScreenTimeService _screenTime = ScreenTimeService.instance;
  final LiveActivityService _liveActivities = LiveActivityService.instance;
  final WidgetService _widgetService = WidgetService.instance;

  ScreenTimeService get screenTime => _screenTime;

  // -------------------------------------------------------------------------
  // Companion State
  // -------------------------------------------------------------------------
  String userName = 'Friend';
  CatColorPalette catColor = CatColorPalette.cream;
  CatPose pose = CatPose.sit;

  // Size and animation speed controls
  double catScale = 0.85; // 0.50x to 1.60x
  double animSpeed = 0.80; // 0.30x to 2.00x

  // 2D position: (0, 0) is default Dynamic Island perch
  double catXOffset = 0.0;
  double catYOffset = 0.0;
  bool facingRight = true;
  bool isHidden = false;
  bool isPatrolling = true;

  // Controls
  bool wanderEnabled = true;
  bool followFinger = false;
  bool dozeOffBetweenWanders = true;
  bool typeAlongEnabled = false;
  bool isUserTyping = false;

  // Mood / Mode Lock: Once user assigns a mood, cat strictly keeps it
  bool isMoodLocked = false;
  CatPose? lockedPose;

  // Audio / Sound / Voice Options
  bool soundEnabled = true;
  bool voiceEnabled = true;
  double soundVolume = 0.8;

  // Modals & Native Integrations
  bool isSettingsOpen = false;
  bool liveActivityEnabled = true;
  bool pipEnabled = true;

  // -------------------------------------------------------------------------
  // Chat & Command Box
  // -------------------------------------------------------------------------
  bool isChatOpen = false;
  String speechBubble = 'Double-tap to chat · Triple-tap for Settings! 🐾';
  final TextEditingController chatController = TextEditingController();

  final List<String> quickChips = const [
    'battery?',
    'memory?',
    'weather?',
    'closed today?',
    '/timer 25',
    '/snooze 30',
    '/remind call Kavi at 5pm',
  ];

  // -------------------------------------------------------------------------
  // Timers & Data (Timestamp-based for background accuracy)
  // -------------------------------------------------------------------------
  DateTime? focusEndTime;
  DateTime? snoozeEndTime;
  int focusSecondsRemaining = 0;
  int snoozeSecondsRemaining = 0;

  List<CatNote> notes = [];
  List<CatReminder> reminders = [];
  List<String> closedTabsToday = ['youtube.com/shorts'];
  String lastResetDate = '';

  // -------------------------------------------------------------------------
  // Apple Screen Time & Native App Limits (YouTube, Instagram, TikTok, etc.)
  // -------------------------------------------------------------------------
  List<ScreenTimeAppRule> screenTimeApps = [
    ScreenTimeAppRule(
      appName: 'YouTube',
      bundleId: 'com.google.ios.youtube',
      urlScheme: 'youtube://',
      icon: '▶️',
      dailyMinutes: 20,
      secondsUsedToday: 0,
    ),
    ScreenTimeAppRule(
      appName: 'Instagram',
      bundleId: 'com.burbn.instagram',
      urlScheme: 'instagram://',
      icon: '📸',
      dailyMinutes: 15,
      secondsUsedToday: 0,
    ),
    ScreenTimeAppRule(
      appName: 'TikTok',
      bundleId: 'com.zhiliaoapp.musically',
      urlScheme: 'snssdk1233://',
      icon: '🎵',
      dailyMinutes: 0, // 0 = instant swat
      secondsUsedToday: 0,
    ),
    ScreenTimeAppRule(
      appName: 'X / Twitter',
      bundleId: 'com.atebits.Tweetie2',
      urlScheme: 'twitter://',
      icon: '🐦',
      dailyMinutes: 30,
      secondsUsedToday: 0,
    ),
    ScreenTimeAppRule(
      appName: 'Reddit',
      bundleId: 'com.reddit.Reddit',
      urlScheme: 'reddit://',
      icon: '🤖',
      dailyMinutes: 25,
      secondsUsedToday: 0,
    ),
  ];

  // -------------------------------------------------------------------------
  // Browser / Watch-and-Close Workspace State
  // -------------------------------------------------------------------------
  bool isAppInForeground = true;
  bool isSwattingInProgress = false;
  int activeTabIndex = 1;

  List<WatchedSiteRule> watchedSites = [
    WatchedSiteRule(
      domain: 'youtube.com/shorts',
      dailyMinutes: 1,
      secondsUsedToday: 50,
    ),
    WatchedSiteRule(domain: 'instagram.com', dailyMinutes: 15),
    WatchedSiteRule(domain: 'reddit.com', dailyMinutes: 0),
  ];

  List<FocusBrowserTab> browserTabs = [
    FocusBrowserTab(
      id: 'tab_docs',
      title: 'docs — spec',
      url: 'https://flutter.dev/docs',
    ),
    FocusBrowserTab(
      id: 'tab_shorts',
      title: 'Shorts — YouTube',
      url: 'https://www.youtube.com/shorts',
    ),
  ];

  // -------------------------------------------------------------------------
  // Internal Timers
  // -------------------------------------------------------------------------
  Timer? _heartbeatTimer;
  Timer? _spriteFrameTimer;
  final Random _rng = Random();

  bool waterReminderEnabled = true;
  bool _isInitialized = false;

  String get catEmoji {
    switch (pose) {
      case CatPose.sleep:
        return '🐱💤';
      case CatPose.pat:
        return '😻';
      case CatPose.greet:
        return '😸';
      case CatPose.angry:
      case CatPose.confront:
        return '😾';
      default:
        return '🐾';
    }
  }

  // -------------------------------------------------------------------------
  // Init / Dispose
  // -------------------------------------------------------------------------
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);
    await _notifications.init();
    await _sound.init();
    await _liveActivities.init();
    await _widgetService.init();
    await _loadPersistedData();
    _checkMidnightReset();
    updateHomeScreenWidget(force: true);

    if (waterReminderEnabled) {
      await _notifications.startHourlyWaterReminder();
    }

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onSecondTick();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _spriteFrameTimer?.cancel();
    chatController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    isAppInForeground = (state == AppLifecycleState.resumed);
    if (isAppInForeground) {
      _checkMidnightReset();
      // Recalculate remaining seconds dynamically from end timestamps
      if (focusEndTime != null) {
        final diff = focusEndTime!.difference(DateTime.now()).inSeconds;
        focusSecondsRemaining = max(0, diff);
        if (focusSecondsRemaining == 0) {
          focusEndTime = null;
          if (!isMoodLocked) pose = CatPose.greet;
          _sound.playTimerChime();
          setSpeechBubble(
            'Focus session complete! 🔔 Take a short break & drink water 💧',
          );
          _notifications.showFocusComplete();
        }
      }

      if (snoozeEndTime != null) {
        final diff = snoozeEndTime!.difference(DateTime.now()).inSeconds;
        snoozeSecondsRemaining = max(0, diff);
        if (snoozeSecondsRemaining == 0) {
          snoozeEndTime = null;
          isPatrolling = true;
          if (!isMoodLocked) pose = CatPose.sit;
          setSpeechBubble('Snooze finished! Back on patrol. 👀');
          _sound.playMeow();
        }
      }
    }
    updateLiveActivity();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Midnight Quota Reset
  // -------------------------------------------------------------------------
  void _checkMidnightReset() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastResetDate.isNotEmpty && lastResetDate != today) {
      debugPrint('[CatViewModel] Midnight reset! Resetting daily quotas.');
      for (final site in watchedSites) {
        site.secondsUsedToday = 0;
      }
      for (final app in screenTimeApps) {
        app.secondsUsedToday = 0;
        app.isBlocked = false;
      }
      closedTabsToday.clear();
      lastResetDate = today;
      _persistData();
      notifyListeners();
    } else if (lastResetDate.isEmpty) {
      lastResetDate = today;
      _persistData();
    }
  }

  // -------------------------------------------------------------------------
  // Speech Bubble & Voice
  // -------------------------------------------------------------------------
  void setSpeechBubble(String text, {bool speakAloud = true}) {
    speechBubble = text;
    if (speakAloud && soundEnabled && voiceEnabled) {
      _sound.speak(text);
    }
    updateLiveActivity();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Dynamic Island / Live Activity & iOS Home Screen Widget Update
  // -------------------------------------------------------------------------
  String get catMoodName {
    if (isMoodLocked && lockedPose != null) {
      return lockedPose!.name.toUpperCase();
    }
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

  void updateLiveActivity({bool force = false}) {
    final activeRule = getActiveWatchedRule();
    String target = '';
    if (activeRule != null) {
      target = activeRule.domain;
    } else if (screenTimeApps.any((a) => a.isBlocked)) {
      target = screenTimeApps.firstWhere((a) => a.isBlocked).appName;
    }

    String title = 'FocusCat';
    int remSeconds = 0;
    double? endTime;

    if (focusEndTime != null) {
      title = 'Focus Session';
      remSeconds = focusSecondsRemaining;
      endTime = focusEndTime!.millisecondsSinceEpoch / 1000.0;
    } else if (snoozeEndTime != null) {
      title = 'Snooze Patrol';
      remSeconds = snoozeSecondsRemaining;
      endTime = snoozeEndTime!.millisecondsSinceEpoch / 1000.0;
    } else if (activeRule != null) {
      title = 'Watched Tab';
      remSeconds = activeRule.remainingSeconds;
    }

    if (liveActivityEnabled || force) {
      _liveActivities.update(
        catPose: pose.name,
        catEmoji: catEmoji,
        statusText: speechBubble,
        title: title,
        remainingSeconds: remSeconds,
        endTimeTimestamp: endTime,
        isPatrolling: isPatrolling,
        targetAppOrDomain: target,
      );
    }

    updateHomeScreenWidget(force: force);
  }

  /// Sends the current cat, mood, timer, and patrol state to the iOS Home Screen Widget.
  Future<void> updateHomeScreenWidget({bool force = false}) async {
    final activeRule = getActiveWatchedRule();
    String target = '';
    if (activeRule != null) {
      target = activeRule.domain;
    } else if (screenTimeApps.any((a) => a.isBlocked)) {
      target = screenTimeApps.firstWhere((a) => a.isBlocked).appName;
    } else if (watchedSites.isNotEmpty) {
      target = watchedSites.first.domain;
    } else {
      target = 'Safari & Apps';
    }

    int remSeconds = 0;
    if (focusEndTime != null) {
      remSeconds = focusSecondsRemaining;
    } else if (snoozeEndTime != null) {
      remSeconds = snoozeSecondsRemaining;
    } else if (activeRule != null) {
      remSeconds = activeRule.remainingSeconds;
    }

    await _widgetService.updateWidgetData(
      catPose: pose.name,
      catEmoji: catEmoji,
      catMood: catMoodName,
      speechBubble: speechBubble,
      isPatrolling: isPatrolling,
      focusSecondsRemaining: remSeconds,
      focusEndTime: focusEndTime,
      targetAppOrDomain: target,
      dailyFocusMinutes: 25,
      company: 'LKS.pvt.ltd company',
    );
  }

  // -------------------------------------------------------------------------
  // Snap Back & Reset Cat Position to Home Perch
  // -------------------------------------------------------------------------
  void resetCatPosition() {
    catXOffset = 0.0;
    catYOffset = 0.0;
    if (!isMoodLocked) pose = CatPose.sit;
    _sound.playMeow();
    setSpeechBubble('Back at my home perch! 🏝️', speakAloud: true);
    notifyListeners();
  }

  void snapBackToDynamicIsland() => resetCatPosition();

  void setSettingsOpen(bool open) {
    isSettingsOpen = open;
    notifyListeners();
  }

  void setLiveActivityEnabled(bool val) {
    liveActivityEnabled = val;
    notifyListeners();
    _persistData();
    if (val) {
      updateLiveActivity(force: true);
    } else {
      _liveActivities.endActivity();
    }
  }

  void setPipEnabled(bool val) {
    pipEnabled = val;
    notifyListeners();
    _persistData();
  }

  // Focus Timer Presets (25m Pomodoro, 15m Break, 45m Deep Work)
  void startFocusPreset(int minutes) {
    focusEndTime = DateTime.now().add(Duration(minutes: minutes));
    focusSecondsRemaining = minutes * 60;
    isPatrolling = true;
    _sound.playTimerChime();
    setSpeechBubble('Started ${minutes}m focus session! 🍅 Let\'s get to work.', speakAloud: true);
    _notifications.scheduleFocusTimer(minutes * 60);
    updateLiveActivity(force: true);
    notifyListeners();
  }

  void pauseFocusTimer() {
    focusEndTime = null;
    setSpeechBubble('Focus session paused. ⏸️', speakAloud: false);
    _sound.playClick();
    updateLiveActivity(force: true);
    notifyListeners();
  }

  void resetFocusTimer() {
    focusEndTime = null;
    focusSecondsRemaining = 0;
    setSpeechBubble('Focus session reset. ✨', speakAloud: false);
    _sound.playClick();
    updateLiveActivity(force: true);
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Heartbeat — 1-second tick
  // -------------------------------------------------------------------------
  void _onSecondTick() {
    _checkMidnightReset();

    // 1. Focus session countdown (timestamp-based)
    if (focusEndTime != null) {
      final diff = focusEndTime!.difference(DateTime.now()).inSeconds;
      focusSecondsRemaining = max(0, diff);
      if (focusSecondsRemaining == 0) {
        focusEndTime = null;
        if (!isMoodLocked) pose = CatPose.greet;
        _sound.playTimerChime();
        setSpeechBubble(
          'Focus session complete! 🔔 Take a short break & drink water 💧',
        );
        _notifications.showFocusComplete();
        updateLiveActivity();
      }
    } else {
      focusSecondsRemaining = 0;
    }

    // 2. Snooze countdown (timestamp-based)
    if (snoozeEndTime != null) {
      final diff = snoozeEndTime!.difference(DateTime.now()).inSeconds;
      snoozeSecondsRemaining = max(0, diff);
      if (snoozeSecondsRemaining == 0) {
        snoozeEndTime = null;
        isPatrolling = true;
        if (!isMoodLocked) pose = CatPose.sit;
        setSpeechBubble('Snooze finished! Back on patrol. 👀');
        _sound.playMeow();
        _notifications.showSnoozeEnded();
        updateLiveActivity();
      }
    } else {
      snoozeSecondsRemaining = 0;
    }

    // 3. Active reminder evaluation
    final now = DateTime.now();
    for (final rem in reminders) {
      if (!rem.isTriggered && now.isAfter(rem.triggerAt)) {
        rem.isTriggered = true;
        if (!isMoodLocked) pose = CatPose.greet;
        _sound.playTimerChime();
        setSpeechBubble('Reminder: "${rem.title}"! ⏰');
        _persistData();
      }
    }

    // 4. In-App Watch & Close foreground tab countdown
    final activeRule = getActiveWatchedRule();
    if (isPatrolling &&
        snoozeSecondsRemaining == 0 &&
        isAppInForeground &&
        !isSwattingInProgress &&
        activeRule != null) {
      if (activeRule.remainingSeconds <= 0) {
        walkAndSwatActiveTab(activeRule);
      } else {
        activeRule.secondsUsedToday++;
        if (activeRule.remainingSeconds <= 5 && !isMoodLocked) {
          pose = CatPose.angry;
        }
        if (activeRule.remainingSeconds <= 0) {
          walkAndSwatActiveTab(activeRule);
        }
      }
    }

    // 5. Apple Screen Time active app countdown
    if (isPatrolling && isAppInForeground && !isSwattingInProgress) {
      for (final app in screenTimeApps) {
        if (app.dailyMinutes > 0 && app.remainingSeconds <= 0 && !app.isBlocked) {
          app.isBlocked = true;
          walkAndSwatNativeApp(app);
          break;
        }
      }
    }

    // 6. Autonomous Cat Movement (Respects user's assigned mood!)
    if (!isUserTyping && !isSwattingInProgress) {
      if (isMoodLocked && lockedPose != null) {
        pose = lockedPose!;
      } else {
        if (wanderEnabled) {
          if (_rng.nextInt(12) == 0 && dozeOffBetweenWanders) {
            pose = CatPose.sleep;
          } else if (_rng.nextInt(8) == 0) {
            pose = CatPose.walk;
          }
        }
      }

      // Horizontal wander across screen
      if (wanderEnabled && (pose == CatPose.walk || !isMoodLocked)) {
        final step = 8.0 * animSpeed * (facingRight ? 1 : -1);
        catXOffset += step;
        if (catXOffset > 130) {
          catXOffset = 130;
          facingRight = false;
        } else if (catXOffset < -130) {
          catXOffset = -130;
          facingRight = true;
        }
      }
    }

    updateLiveActivity();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Swat Actions
  // -------------------------------------------------------------------------
  void walkAndSwatActiveTab(WatchedSiteRule rule) {
    if (isSwattingInProgress) return;
    isSwattingInProgress = true;
    pose = CatPose.confront;
    setSpeechBubble('Daily limit reached for ${rule.domain}! Swatting! 🐾');
    _sound.playSwat();

    Future.delayed(const Duration(milliseconds: 650), () {
      if (activeTabIndex < browserTabs.length) {
        closedTabsToday.insert(0, rule.domain);
        browserTabs.removeAt(activeTabIndex);
        if (activeTabIndex >= browserTabs.length) {
          activeTabIndex = max(0, browserTabs.length - 1);
        }
      }
      isSwattingInProgress = false;
      pose = isMoodLocked && lockedPose != null ? lockedPose! : CatPose.sit;
      catXOffset = 0.0;
      setSpeechBubble('Swatted ${rule.domain} closed! Your other tabs stayed open. 🐾');
      _notifications.showTabSwatted(rule.domain);
      _persistData();
      notifyListeners();
    });
  }

  void walkAndSwatNativeApp(ScreenTimeAppRule app) {
    if (isSwattingInProgress) return;
    isSwattingInProgress = true;
    pose = CatPose.confront;
    setSpeechBubble('Daily Screen Time limit for ${app.appName} hit! Shielding! 😼');
    _sound.playSwat();

    Future.delayed(const Duration(milliseconds: 700), () {
      isSwattingInProgress = false;
      pose = isMoodLocked && lockedPose != null ? lockedPose! : CatPose.sit;
      setSpeechBubble('Shielded ${app.appName} via Screen Time! Great focus 🎉');
      closedTabsToday.insert(0, '${app.appName} (Screen Time)');
      _notifications.showTabSwatted(app.appName);
      _persistData();
      notifyListeners();
    });
  }

  /// Strict Host + Path URL Matching (prevents false-positive swats from query parameters)
  WatchedSiteRule? getActiveWatchedRule() {
    if (browserTabs.isEmpty || activeTabIndex >= browserTabs.length) {
      return null;
    }
    final currentUrl = browserTabs[activeTabIndex].url.trim();
    final uri = Uri.tryParse(currentUrl);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    for (final rule in watchedSites) {
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

  void selectTab(int index) {
    activeTabIndex = index;
    _sound.playClick();
    notifyListeners();
  }

  void closeTab(int index) {
    browserTabs.removeAt(index);
    if (activeTabIndex >= browserTabs.length) {
      activeTabIndex = max(0, browserTabs.length - 1);
    }
    _sound.playClick();
    notifyListeners();
  }

  void reopenYouTubeShorts() {
    for (final r in watchedSites) {
      if (r.domain == 'youtube.com/shorts') {
        r.secondsUsedToday = max(0, r.totalAllowedSeconds - 10);
      }
    }
    browserTabs.add(FocusBrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Shorts — YouTube',
      url: 'https://www.youtube.com/shorts',
    ));
    activeTabIndex = browserTabs.length - 1;
    notifyListeners();
  }

  void updateTabUrl(int index, String url) {
    if (index < browserTabs.length) {
      browserTabs[index].url = url;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Cat Touch & Gesture Interactions
  // -------------------------------------------------------------------------
  void onCatTap() {
    _sound.playPurr();
    if (!isMoodLocked) {
      pose = CatPose.pat;
    }
    setSpeechBubble('Purrrrr... ♥', speakAloud: false);
  }

  void onCatDoubleTap() {
    _sound.playMeow();
    isChatOpen = !isChatOpen;
    if (isChatOpen) {
      if (!isMoodLocked) pose = CatPose.greet;
      setSpeechBubble('Hi $userName! Ask me anything or jot a note.');
    } else {
      notifyListeners();
    }
  }

  /// Triple-tap opens the full Desktop Settings / Control Center window!
  void onCatTripleTap(BuildContext context) {
    _sound.playClick();
    MainSettingsWindow.show(context);
  }

  /// Free 2D Dragging bounded strictly within safe area boundaries
  void onCatDrag2D(
    double dx,
    double dy, {
    double minX = -160.0,
    double maxX = 160.0,
    double minY = 0.0,
    double maxY = 650.0,
  }) {
    catXOffset = (catXOffset + dx).clamp(minX, maxX);
    catYOffset = (catYOffset + dy).clamp(minY, maxY);
    facingRight = dx >= 0;
    if (!isMoodLocked) {
      pose = CatPose.walk;
    }
    notifyListeners();
  }

  void onCatDragEnd() {
    if (!isMoodLocked) {
      pose = CatPose.sit;
    }
    // Snap back if released very close to top Dynamic Island
    if (catYOffset.abs() < 40 && catXOffset.abs() < 50) {
      catXOffset = 0.0;
      catYOffset = 0.0;
    }
    notifyListeners();
  }

  void onTextChanged(String val) {
    isUserTyping = val.isNotEmpty;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Setters & Configuration
  // -------------------------------------------------------------------------
  void setCatScale(double val) {
    catScale = val.clamp(0.50, 1.60);
    notifyListeners();
    _persistData();
  }

  void setAnimSpeed(double val) {
    animSpeed = val.clamp(0.30, 2.00);
    notifyListeners();
    _persistData();
  }

  void setWanderEnabled(bool val) {
    wanderEnabled = val;
    notifyListeners();
    _persistData();
  }

  void setFollowFinger(bool val) {
    followFinger = val;
    notifyListeners();
    _persistData();
  }

  bool get chaseFingerEnabled => followFinger;
  void setChaseFingerEnabled(bool v) => setFollowFinger(v);

  void setDozeOffBetweenWanders(bool val) {
    dozeOffBetweenWanders = val;
    notifyListeners();
    _persistData();
  }

  void setTypeAlongEnabled(bool val) {
    typeAlongEnabled = val;
    notifyListeners();
    _persistData();
  }

  /// Mood lock: Locks the cat into a specific mood/mode indefinitely
  void setMoodLock(bool locked, [CatPose? targetPose]) {
    isMoodLocked = locked;
    if (targetPose != null) {
      lockedPose = targetPose;
      pose = targetPose;
    } else if (locked) {
      lockedPose = pose;
    }
    _sound.playClick();
    notifyListeners();
    _persistData();
  }

  void setPose(CatPose p, [String? bubble]) {
    pose = p;
    lockedPose = p;
    isMoodLocked = true;
    if (bubble != null) {
      setSpeechBubble(bubble);
    } else {
      _sound.playClick();
      notifyListeners();
    }
    _persistData();
  }

  void setCatColor(CatColorPalette color) {
    catColor = color;
    _sound.playClick();
    notifyListeners();
    _persistData();
  }

  void setSoundEnabled(bool val) {
    soundEnabled = val;
    _sound.soundEnabled = val;
    notifyListeners();
    _persistData();
  }

  void setVoiceEnabled(bool val) {
    voiceEnabled = val;
    _sound.voiceEnabled = val;
    notifyListeners();
    _persistData();
  }

  void setSoundVolume(double val) {
    soundVolume = val;
    _sound.volume = val;
    notifyListeners();
    _persistData();
  }

  void updateScreenTimeAppMinutes(ScreenTimeAppRule app, int delta) {
    app.dailyMinutes = max(0, app.dailyMinutes + delta);
    _sound.playClick();
    notifyListeners();
    _persistData();
  }

  /// Preserves secondsUsedToday and persists immediately
  void updateWatchedSiteMinutes(WatchedSiteRule rule, int deltaMinutes) {
    final newMin = max(0, rule.dailyMinutes + deltaMinutes);
    final idx = watchedSites.indexOf(rule);
    if (idx != -1) {
      watchedSites[idx] = rule.copyWith(
        dailyMinutes: newMin,
        secondsUsedToday: rule.secondsUsedToday,
      );
      _sound.playClick();
      _persistData();
      notifyListeners();
    }
  }

  void togglePatrol() {
    isPatrolling = !isPatrolling;
    setSpeechBubble(isPatrolling ? 'Back on patrol! 👀' : 'Patrol paused.');
    _sound.playClick();
    updateLiveActivity();
    notifyListeners();
  }

  void toggleHidden() {
    isHidden = !isHidden;
    _sound.playClick();
    notifyListeners();
  }

  void setWaterReminderEnabled(bool enabled) async {
    waterReminderEnabled = enabled;
    if (enabled) {
      await _notifications.startHourlyWaterReminder();
    } else {
      await _notifications.stopHourlyWaterReminder();
    }
    _sound.playClick();
    notifyListeners();
  }

  void setUserName(String name) {
    if (name.trim().isNotEmpty) {
      userName = name.trim();
      notifyListeners();
      _persistData();
    }
  }

  void snooze30() {
    snoozeEndTime = DateTime.now().add(const Duration(minutes: 30));
    snoozeSecondsRemaining = 30 * 60;
    isPatrolling = false;
    if (!isMoodLocked) pose = CatPose.sleep;
    setSpeechBubble('Snoozing site patrol for 30 min. 😴');
    _sound.playMeow();
    updateLiveActivity();
    notifyListeners();
  }

  /// "Show me what it does" animated demonstration
  Future<void> demoCycle() async {
    final savedMoodLock = isMoodLocked;
    final savedLockedPose = lockedPose;
    isMoodLocked = false;

    setSpeechBubble('Hi! Watch what I can do. 🐾');
    pose = CatPose.greet;
    _sound.playMeow();
    await Future.delayed(const Duration(milliseconds: 1800));

    setSpeechBubble('I walk and patrol your screen...');
    pose = CatPose.walk;
    facingRight = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 2000));

    setSpeechBubble('When petted, I purr! ♥');
    pose = CatPose.pat;
    _sound.playPurr();
    await Future.delayed(const Duration(milliseconds: 1800));

    setSpeechBubble('Distracting site spotted!');
    pose = CatPose.confront;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1500));

    setSpeechBubble('And I nap when you snooze. Zzz...');
    pose = CatPose.sleep;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 2000));

    isMoodLocked = savedMoodLock;
    lockedPose = savedLockedPose;
    pose = isMoodLocked && lockedPose != null ? lockedPose! : CatPose.sit;
    setSpeechBubble('Double-tap to chat · Triple-tap for Settings!', speakAloud: false);
  }

  // -------------------------------------------------------------------------
  // Command Parser
  // -------------------------------------------------------------------------
  Future<void> submitInput({bool forceNote = false}) async {
    final raw = chatController.text.trim();
    if (raw.isEmpty) return;
    chatController.clear();
    isUserTyping = false;
    notifyListeners();

    if (forceNote) {
      _saveQuickNote(raw);
      return;
    }

    final lower = raw.toLowerCase();

    if (lower.startsWith('/timer')) {
      final mins = _extractFirstInt(lower) ?? 25;
      final seconds = max(1, mins) * 60;
      focusEndTime = DateTime.now().add(Duration(seconds: seconds));
      focusSecondsRemaining = seconds;
      if (!isMoodLocked) pose = CatPose.sit;
      setSpeechBubble('Started a $mins-minute focus session! Let\'s work. 🐾');
      _notifications.scheduleFocusTimer(seconds);
      _sound.playClick();
      updateLiveActivity();
      return;
    }

    if (lower.startsWith('/snooze')) {
      final mins = _extractFirstInt(lower) ?? 30;
      snoozeEndTime = DateTime.now().add(Duration(minutes: mins));
      snoozeSecondsRemaining = mins * 60;
      isPatrolling = false;
      if (!isMoodLocked) pose = CatPose.sleep;
      setSpeechBubble('Snoozing site patrol for $mins min. 😴');
      _sound.playMeow();
      updateLiveActivity();
      return;
    }

    if (lower.startsWith('/remind')) {
      _scheduleReminder(raw);
      return;
    }

    if (lower == '/hide') {
      setSpeechBubble('Hiding! Use the Tray menu to bring me back.');
      await Future.delayed(const Duration(milliseconds: 1100));
      isHidden = true;
      isChatOpen = false;
      notifyListeners();
      return;
    }

    if (const ['hi', 'hello', 'hey', 'hi!', 'hello!'].contains(lower)) {
      if (!isMoodLocked) pose = CatPose.greet;
      setSpeechBubble('Meow! Hi $userName! Ready to focus?');
      _sound.playMeow();
      return;
    }

    if (lower == 'help' || lower == 'help?') {
      setSpeechBubble(
        'Ask: battery? memory? cpu? internet? weather? timer? closed today? | /timer 25, /snooze 30, /remind … | Triple-tap cat for Settings!',
      );
      return;
    }

    if (lower.startsWith('battery')) {
      final report = await _telemetry.getBatteryReport();
      if (!isMoodLocked) pose = CatPose.sit;
      setSpeechBubble(report);
      return;
    }

    if (lower.startsWith('memory')) {
      if (!isMoodLocked) pose = CatPose.sit;
      setSpeechBubble(_telemetry.getMemoryReport());
      return;
    }

    if (lower.startsWith('cpu')) {
      if (!isMoodLocked) pose = CatPose.sit;
      setSpeechBubble(_telemetry.getCpuReport());
      return;
    }

    if (lower.startsWith('internet')) {
      final report = await _telemetry.getInternetReport();
      if (!isMoodLocked) pose = CatPose.sit;
      setSpeechBubble(report);
      return;
    }

    if (lower.contains('closed today') || lower.contains('what did i close')) {
      if (closedTabsToday.isEmpty) {
        setSpeechBubble('Zero tabs swatted today! Great focus 🎉');
      } else {
        if (!isMoodLocked) pose = CatPose.confront;
        setSpeechBubble(
          'Swatted ${closedTabsToday.length} tab(s) today: ${closedTabsToday.join(", ")}',
        );
      }
      return;
    }

    if (lower == 'timer?' || lower == 'timer') {
      if (focusSecondsRemaining > 0) {
        setSpeechBubble(
          'Focus timer running: ${formatTime(focusSecondsRemaining)} left! 🍅',
        );
      } else {
        setSpeechBubble('No focus timer running. Type /timer 25 to start one!');
      }
      return;
    }

    if (lower.startsWith('weather')) {
      String city = 'Coimbatore';
      final idx = lower.indexOf('weather in ');
      if (idx != -1) {
        final extracted =
            raw.substring(idx + 'weather in '.length).replaceAll('?', '').trim();
        if (extracted.isNotEmpty) city = extracted;
      }
      setSpeechBubble('Sniffing the wind in $city... 🐾');
      final weatherText = await _telemetry.fetchWeather(city);
      setSpeechBubble(weatherText);
      return;
    }

    _saveQuickNote(raw);
  }

  // -------------------------------------------------------------------------
  // Notes & Reminders
  // -------------------------------------------------------------------------
  void _saveQuickNote(String text) {
    final note = CatNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      createdAt: DateTime.now(),
    );
    notes.insert(0, note);
    if (!isMoodLocked) pose = CatPose.pat;
    setSpeechBubble('Saved note: "$text" 📝');
    _sound.playClick();
    _persistData();
  }

  void deleteNote(CatNote note) {
    notes.remove(note);
    _sound.playClick();
    notifyListeners();
    _persistData();
  }

  void _scheduleReminder(String rawCommand) {
    final body =
        rawCommand.replaceFirst(RegExp(r'^/remind\s+', caseSensitive: false), '');
    String title = body;
    String timeLabel = 'in 30 minutes';

    final atMatch =
        RegExp(r'\bat\s+(.+)$', caseSensitive: false).firstMatch(body);
    if (atMatch != null) {
      timeLabel = atMatch.group(1)!.trim();
      title = body.substring(0, atMatch.start).trim();
    }

    final resolvedTitle = title.isEmpty ? body : title;
    final triggerAt = _notifications.parseTimeString(timeLabel);

    final rem = CatReminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: resolvedTitle,
      timeLabel: timeLabel,
      triggerAt: triggerAt,
      isTriggered: false,
    );
    reminders.insert(0, rem);
    if (!isMoodLocked) pose = CatPose.greet;
    setSpeechBubble('Reminder set: "${rem.title}" ($timeLabel) ⏰');
    _sound.playClick();
    _persistData();

    _notifications.scheduleReminder(
      title: resolvedTitle,
      rawTimeString: timeLabel,
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------
  String formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int? _extractFirstInt(String input) {
    final match = RegExp(r'\d+').firstMatch(input);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  // -------------------------------------------------------------------------
  // Persistence
  // -------------------------------------------------------------------------
  Future<void> _loadPersistedData() async {
    final data = await _persistence.loadAll();
    userName = data['userName'] as String;
    catColor = data['catColor'] as CatColorPalette;
    notes = List<CatNote>.from(data['notes'] as List);
    reminders = List<CatReminder>.from(data['reminders'] as List);

    catScale = (data['catScale'] as double?) ?? 0.85;
    animSpeed = (data['animSpeed'] as double?) ?? 0.80;
    wanderEnabled = (data['wanderEnabled'] as bool?) ?? true;
    followFinger = (data['followFinger'] as bool?) ?? false;
    dozeOffBetweenWanders = (data['dozeOffBetweenWanders'] as bool?) ?? true;
    typeAlongEnabled = (data['typeAlongEnabled'] as bool?) ?? false;

    isMoodLocked = (data['isMoodLocked'] as bool?) ?? false;
    lockedPose = data['lockedPose'] as CatPose?;
    if (isMoodLocked && lockedPose != null) {
      pose = lockedPose!;
    }

    soundEnabled = (data['soundEnabled'] as bool?) ?? true;
    soundVolume = (data['soundVolume'] as double?) ?? 0.8;
    voiceEnabled = (data['voiceEnabled'] as bool?) ?? true;
    liveActivityEnabled = (data['liveActivityEnabled'] as bool?) ?? true;
    pipEnabled = (data['pipEnabled'] as bool?) ?? true;
    _sound.soundEnabled = soundEnabled;
    _sound.volume = soundVolume;
    _sound.voiceEnabled = voiceEnabled;

    lastResetDate = (data['lastResetDate'] as String?) ?? '';
    final loadedClosed = data['closedTabsToday'] as List<String>?;
    if (loadedClosed != null && loadedClosed.isNotEmpty) {
      closedTabsToday = loadedClosed;
    }

    final loadedSites = data['watchedSites'] as List<WatchedSiteRule>?;
    if (loadedSites != null && loadedSites.isNotEmpty) {
      watchedSites = loadedSites;
    }

    final loadedApps = data['screenTimeApps'] as List<ScreenTimeAppRule>?;
    if (loadedApps != null && loadedApps.isNotEmpty) {
      screenTimeApps = loadedApps;
    }

    notifyListeners();
  }

  Future<void> _persistData() async {
    await _persistence.saveAll(
      userName: userName,
      catColor: catColor,
      notes: notes,
      reminders: reminders,
      catScale: catScale,
      animSpeed: animSpeed,
      wanderEnabled: wanderEnabled,
      followFinger: followFinger,
      dozeOffBetweenWanders: dozeOffBetweenWanders,
      typeAlongEnabled: typeAlongEnabled,
      isMoodLocked: isMoodLocked,
      lockedPose: lockedPose,
      soundEnabled: soundEnabled,
      soundVolume: soundVolume,
      voiceEnabled: voiceEnabled,
      liveActivityEnabled: liveActivityEnabled,
      pipEnabled: pipEnabled,
      screenTimeApps: screenTimeApps,
      watchedSites: watchedSites,
      closedTabsToday: closedTabsToday,
      lastResetDate: lastResetDate,
    );
  }
}
