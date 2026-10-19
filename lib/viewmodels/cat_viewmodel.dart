// lib/viewmodels/cat_viewmodel.dart
// Central ChangeNotifier ViewModel for FocusCat iOS v3.0.
// Handles companion state, mood locking, 2D dragging, Screen Time app limits, and sounds.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/cat_models.dart';
import '../services/cat_sound_service.dart';
import '../services/notification_service.dart';
import '../services/persistence_service.dart';
import '../services/screen_time_service.dart';
import '../services/telemetry_service.dart';
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

  ScreenTimeService get screenTime => _screenTime;

  // -------------------------------------------------------------------------
  // Companion State
  // -------------------------------------------------------------------------
  String userName = 'Friend';
  CatColorPalette catColor = CatColorPalette.cream;
  CatPose pose = CatPose.sit;

  // Size and animation speed controls (from user screenshot)
  double catScale = 0.85; // 0.50x to 1.60x
  double animSpeed = 0.80; // 0.30x to 2.00x

  // 2D position for dragging across entire screen and outside tabs
  double catXOffset = 0.0;
  double catYOffset = 0.0;
  bool facingRight = true;
  bool isHidden = false;
  bool isPatrolling = true;

  // Controls from user screenshot
  bool wanderEnabled = true;
  bool followFinger = false;
  bool dozeOffBetweenWanders = true;
  bool typeAlongEnabled = false;
  bool isUserTyping = false;

  // Mood / Mode Lock: Once user assigns a mood, cat strictly keeps it
  bool isMoodLocked = false;
  CatPose? lockedPose;

  // Audio / Sound Options
  bool soundEnabled = true;
  double soundVolume = 0.8;

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
  // Timers & Data
  // -------------------------------------------------------------------------
  int focusSecondsRemaining = 0;
  int snoozeSecondsRemaining = 0;
  List<CatNote> notes = [];
  List<CatReminder> reminders = [];
  List<String> closedTabsToday = ['youtube.com/shorts'];

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

  // -------------------------------------------------------------------------
  // Init / Dispose
  // -------------------------------------------------------------------------
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);
    await _notifications.init();
    await _loadPersistedData();

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
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Heartbeat — 1-second tick
  // -------------------------------------------------------------------------
  void _onSecondTick() {
    // 1. Focus session countdown
    if (focusSecondsRemaining > 0) {
      focusSecondsRemaining--;
      if (focusSecondsRemaining == 0) {
        if (!isMoodLocked) pose = CatPose.greet;
        _sound.playTimerChime();
        speechBubble =
            'Focus session complete! 🔔 Take a short break & drink water 💧';
        _notifications.showFocusComplete();
      }
    }

    // 2. Snooze countdown
    if (snoozeSecondsRemaining > 0) {
      snoozeSecondsRemaining--;
      if (snoozeSecondsRemaining == 0) {
        isPatrolling = true;
        if (!isMoodLocked) pose = CatPose.sit;
        speechBubble = 'Snooze finished! Back on patrol. 👀';
        _sound.playMeow();
        _notifications.showSnoozeEnded();
      }
    }

    // 3. In-App Watch & Close foreground tab countdown
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

    // 4. Apple Screen Time active app countdown
    if (isPatrolling && isAppInForeground && !isSwattingInProgress) {
      for (final app in screenTimeApps) {
        if (app.dailyMinutes > 0 && app.remainingSeconds <= 0 && !app.isBlocked) {
          app.isBlocked = true;
          walkAndSwatNativeApp(app);
          break;
        }
      }
    }

    // 5. Autonomous Cat Movement (Respects user's assigned mood!)
    if (!isUserTyping && !isSwattingInProgress) {
      if (isMoodLocked && lockedPose != null) {
        // Strict adherence to user's assigned mood
        pose = lockedPose!;
      } else {
        // Natural wandering if wanderEnabled is true
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

    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Swat Actions
  // -------------------------------------------------------------------------
  void walkAndSwatActiveTab(WatchedSiteRule rule) {
    if (isSwattingInProgress) return;
    isSwattingInProgress = true;
    pose = CatPose.confront;
    speechBubble = 'Daily limit reached for ${rule.domain}! Swatting! 🐾';
    _sound.playSwat();
    notifyListeners();

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
      speechBubble =
          'Swatted ${rule.domain} closed! Your other tabs stayed open. 🐾';
      _notifications.showTabSwatted(rule.domain);
      _persistData();
      notifyListeners();
    });
  }

  void walkAndSwatNativeApp(ScreenTimeAppRule app) {
    if (isSwattingInProgress) return;
    isSwattingInProgress = true;
    pose = CatPose.confront;
    speechBubble = 'Daily Screen Time limit for ${app.appName} hit! Shielding! 😼';
    _sound.playSwat();
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 700), () {
      isSwattingInProgress = false;
      pose = isMoodLocked && lockedPose != null ? lockedPose! : CatPose.sit;
      speechBubble = 'Shielded ${app.appName} via Screen Time! Great focus 🎉';
      closedTabsToday.insert(0, '${app.appName} (Screen Time)');
      _notifications.showTabSwatted(app.appName);
      _persistData();
      notifyListeners();
    });
  }

  WatchedSiteRule? getActiveWatchedRule() {
    if (browserTabs.isEmpty || activeTabIndex >= browserTabs.length) {
      return null;
    }
    final currentUrl = browserTabs[activeTabIndex].url.toLowerCase();
    for (final rule in watchedSites) {
      if (currentUrl.contains(rule.domain.toLowerCase())) {
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
    speechBubble = 'Purrrrr... ♥';
    notifyListeners();
  }

  void onCatDoubleTap() {
    _sound.playMeow();
    isChatOpen = !isChatOpen;
    if (isChatOpen) {
      if (!isMoodLocked) pose = CatPose.greet;
      speechBubble = 'Hi $userName! Ask me anything or jot a note.';
    }
    notifyListeners();
  }

  /// Triple-tap opens the full Desktop Settings / Control Center window!
  void onCatTripleTap(BuildContext context) {
    _sound.playClick();
    MainSettingsWindow.show(context);
  }

  /// Free 2D Dragging across the entire screen and outside the tab!
  void onCatDrag2D(double dx, double dy) {
    catXOffset = (catXOffset + dx).clamp(-500.0, 500.0);
    catYOffset = (catYOffset + dy).clamp(-850.0, 250.0);
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
    isMoodLocked = true; // Once user assigns a mood, lock it!
    if (bubble != null) {
      speechBubble = bubble;
    }
    _sound.playClick();
    notifyListeners();
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

  void updateWatchedSiteMinutes(WatchedSiteRule rule, int deltaMinutes) {
    final newMin = max(0, rule.dailyMinutes + deltaMinutes);
    final idx = watchedSites.indexOf(rule);
    if (idx != -1) {
      watchedSites[idx] = rule.copyWith(dailyMinutes: newMin);
      _sound.playClick();
      notifyListeners();
    }
  }

  void togglePatrol() {
    isPatrolling = !isPatrolling;
    speechBubble = isPatrolling ? 'Back on patrol! 👀' : 'Patrol paused.';
    _sound.playClick();
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
    snoozeSecondsRemaining = 30 * 60;
    isPatrolling = false;
    if (!isMoodLocked) pose = CatPose.sleep;
    speechBubble = 'Snoozing site patrol for 30 min. 😴';
    _sound.playMeow();
    notifyListeners();
  }

  /// "Show me what it does" animated demonstration
  Future<void> demoCycle() async {
    final savedMoodLock = isMoodLocked;
    final savedLockedPose = lockedPose;
    isMoodLocked = false;

    speechBubble = 'Hi! Watch what I can do. 🐾';
    pose = CatPose.greet;
    _sound.playMeow();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1800));

    speechBubble = 'I walk and patrol your screen...';
    pose = CatPose.walk;
    facingRight = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 2000));

    speechBubble = 'When petted, I purr! ♥';
    pose = CatPose.pat;
    _sound.playPurr();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1800));

    speechBubble = 'Distracting site spotted!';
    pose = CatPose.confront;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1500));

    speechBubble = 'And I nap when you snooze. Zzz...';
    pose = CatPose.sleep;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 2000));

    isMoodLocked = savedMoodLock;
    lockedPose = savedLockedPose;
    pose = isMoodLocked && lockedPose != null ? lockedPose! : CatPose.sit;
    speechBubble = 'Double-tap to chat · Triple-tap for Settings!';
    notifyListeners();
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
      focusSecondsRemaining = seconds;
      if (!isMoodLocked) pose = CatPose.sit;
      speechBubble = 'Started a $mins-minute focus session! Let\'s work. 🐾';
      _notifications.scheduleFocusTimer(seconds);
      _sound.playClick();
      notifyListeners();
      return;
    }

    if (lower.startsWith('/snooze')) {
      final mins = _extractFirstInt(lower) ?? 30;
      snoozeSecondsRemaining = mins * 60;
      isPatrolling = false;
      if (!isMoodLocked) pose = CatPose.sleep;
      speechBubble = 'Snoozing site patrol for $mins min. 😴';
      _sound.playMeow();
      notifyListeners();
      return;
    }

    if (lower.startsWith('/remind')) {
      _scheduleReminder(raw);
      return;
    }

    if (lower == '/hide') {
      speechBubble = 'Hiding! Use the Tray menu to bring me back.';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 1100));
      isHidden = true;
      isChatOpen = false;
      notifyListeners();
      return;
    }

    if (const ['hi', 'hello', 'hey', 'hi!', 'hello!'].contains(lower)) {
      if (!isMoodLocked) pose = CatPose.greet;
      speechBubble = 'Meow! Hi $userName! Ready to focus?';
      _sound.playMeow();
      notifyListeners();
      return;
    }

    if (lower == 'help' || lower == 'help?') {
      speechBubble =
          'Ask: battery? memory? cpu? internet? weather? timer? closed today? | /timer 25, /snooze 30, /remind … | Triple-tap cat for Settings!';
      notifyListeners();
      return;
    }

    if (lower.startsWith('battery')) {
      final report = await _telemetry.getBatteryReport();
      if (!isMoodLocked) pose = CatPose.sit;
      speechBubble = report;
      notifyListeners();
      return;
    }

    if (lower.startsWith('memory')) {
      if (!isMoodLocked) pose = CatPose.sit;
      speechBubble = _telemetry.getMemoryReport();
      notifyListeners();
      return;
    }

    if (lower.startsWith('cpu')) {
      if (!isMoodLocked) pose = CatPose.sit;
      speechBubble = _telemetry.getCpuReport();
      notifyListeners();
      return;
    }

    if (lower.startsWith('internet')) {
      final report = await _telemetry.getInternetReport();
      if (!isMoodLocked) pose = CatPose.sit;
      speechBubble = report;
      notifyListeners();
      return;
    }

    if (lower.contains('closed today') || lower.contains('what did i close')) {
      if (closedTabsToday.isEmpty) {
        speechBubble = 'Zero tabs swatted today! Great focus 🎉';
      } else {
        if (!isMoodLocked) pose = CatPose.confront;
        speechBubble =
            'Swatted ${closedTabsToday.length} tab(s) today: ${closedTabsToday.join(", ")}';
      }
      notifyListeners();
      return;
    }

    if (lower == 'timer?' || lower == 'timer') {
      if (focusSecondsRemaining > 0) {
        speechBubble =
            'Focus timer running: ${formatTime(focusSecondsRemaining)} left! 🍅';
      } else {
        speechBubble = 'No focus timer running. Type /timer 25 to start one!';
      }
      notifyListeners();
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
      speechBubble = 'Sniffing the wind in $city... 🐾';
      notifyListeners();
      final weatherText = await _telemetry.fetchWeather(city);
      speechBubble = weatherText;
      notifyListeners();
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
    speechBubble = 'Saved note: "$text" 📝';
    _sound.playClick();
    notifyListeners();
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
    String timeLabel = 'Soon';

    final atMatch =
        RegExp(r'\bat\s+(.+)$', caseSensitive: false).firstMatch(body);
    if (atMatch != null) {
      timeLabel = atMatch.group(1)!.trim();
      title = body.substring(0, atMatch.start).trim();
    }

    final resolvedTitle = title.isEmpty ? body : title;
    final rem = CatReminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: resolvedTitle,
      timeLabel: timeLabel,
    );
    reminders.insert(0, rem);
    if (!isMoodLocked) pose = CatPose.greet;
    speechBubble = 'Reminder set: "${rem.title}" ($timeLabel) ⏰';
    _sound.playClick();
    notifyListeners();
    _persistData();

    _notifications
        .scheduleReminder(title: resolvedTitle, rawTimeString: timeLabel)
        .then((fireAt) {
      debugPrint('[CatViewModel] Reminder "$resolvedTitle" will fire at $fireAt');
    });
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
    _sound.soundEnabled = soundEnabled;
    _sound.volume = soundVolume;

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
      screenTimeApps: screenTimeApps,
    );
  }
}
