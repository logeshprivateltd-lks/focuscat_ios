// lib/views/browser_workspace_view.dart
// The full Watch-and-Close multi-tab browser workspace.
// Supports native WebView on iOS/Android, with a graceful desktop preview fallback.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/cat_models.dart';
import '../viewmodels/cat_viewmodel.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:io' show Platform;

class BrowserWorkspaceView extends StatefulWidget {
  const BrowserWorkspaceView({super.key});

  @override
  State<BrowserWorkspaceView> createState() => _BrowserWorkspaceViewState();
}

class _BrowserWorkspaceViewState extends State<BrowserWorkspaceView> {
  WebViewController? _webViewController;
  final TextEditingController _urlController = TextEditingController();
  bool _showUrlBar = false;

  bool get _supportsNativeWebView =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _initWebView() {
    if (!_supportsNativeWebView) return;
    final vm = context.read<CatViewModel>();
    if (vm.browserTabs.isEmpty) return;
    final url = vm.browserTabs[vm.activeTabIndex].url;
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onUrlChange: (change) {
          if (change.url != null && mounted) {
            vm.updateTabUrl(vm.activeTabIndex, change.url!);
            _urlController.text = change.url!;
          }
        },
      ))
      ..loadRequest(Uri.parse(url));
    _urlController.text = url;
  }

  void _onTabSelected(int index) {
    final vm = context.read<CatViewModel>();
    vm.selectTab(index);
    if (_supportsNativeWebView && vm.browserTabs.isNotEmpty) {
      final url = vm.browserTabs[index].url;
      _webViewController?.loadRequest(Uri.parse(url));
      _urlController.text = url;
    }
  }

  void _navigateToUrl(String rawUrl) {
    String url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final vm = context.read<CatViewModel>();
    vm.updateTabUrl(vm.activeTabIndex, url);
    _webViewController?.loadRequest(Uri.parse(url));
    _urlController.text = url;
    setState(() => _showUrlBar = false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatViewModel>();
    final activeRule = vm.getActiveWatchedRule();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: activeRule != null
              ? Colors.orangeAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Tab strip + URL bar
          _buildTabStrip(vm),

          // URL bar (toggle)
          if (_showUrlBar) _buildUrlBar(),

          // Patrol HUD pill
          if (activeRule != null) _buildPatrolHudPill(vm, activeRule),

          // Swat overlay
          if (vm.isSwattingInProgress) _buildSwatOverlay(),

          // Viewport
          Expanded(child: _buildViewport(vm, activeRule)),
        ],
      ),
    );
  }

  Widget _buildTabStrip(CatViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(vm.browserTabs.length, (index) {
                  final tab = vm.browserTabs[index];
                  final isSelected = index == vm.activeTabIndex;
                  return GestureDetector(
                    onTap: () => _onTabSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF282C3E)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.white24)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.title,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              vm.closeTab(index);
                              if (_supportsNativeWebView &&
                                  vm.browserTabs.isNotEmpty) {
                                _webViewController?.loadRequest(Uri.parse(
                                    vm.browserTabs[vm.activeTabIndex].url));
                              }
                            },
                            child: const Icon(Icons.close,
                                size: 13, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // URL bar toggle
          if (_supportsNativeWebView)
            IconButton(
              icon: Icon(
                _showUrlBar ? Icons.close : Icons.search,
                size: 16,
                color: Colors.white54,
              ),
              onPressed: () => setState(() => _showUrlBar = !_showUrlBar),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

          // Reopen YouTube Shorts
          TextButton.icon(
            onPressed: () {
              vm.reopenYouTubeShorts();
              if (_supportsNativeWebView) {
                _webViewController?.loadRequest(Uri.parse(
                    vm.browserTabs[vm.activeTabIndex].url));
              }
            },
            icon: const Icon(Icons.replay, size: 13),
            label: const Text(
              '▸ again',
              style: TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _urlController,
        autofocus: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Enter URL (e.g. github.com)',
          hintStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.35),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, size: 18),
            onPressed: () => _navigateToUrl(_urlController.text),
          ),
        ),
        onSubmitted: _navigateToUrl,
      ),
    );
  }

  Widget _buildPatrolHudPill(CatViewModel vm, WatchedSiteRule rule) {
    final rem = rule.remainingSeconds;
    final remLabel = rem >= 60 ? '${rem ~/ 60}m ${rem % 60}s' : '$rem s';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.orangeAccent.withValues(alpha: 0.12),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _hudStat('watching', rule.domain, Colors.white),
          _hudStat('you get', '${rule.dailyMinutes} min', Colors.white70),
          _hudStat(
            'time left',
            remLabel,
            rem <= 5 ? Colors.redAccent : Colors.amberAccent,
          ),
          _hudStat(
            'status',
            !vm.isPatrolling
                ? 'paused'
                : (vm.isAppInForeground
                    ? 'watching'
                    : 'paused (background)'),
            Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _hudStat(String label, String value, Color valueColor) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        children: [
          TextSpan(
              text: '$label ',
              style: const TextStyle(color: Colors.white54)),
          TextSpan(
              text: value,
              style:
                  TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSwatOverlay() {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.redAccent, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildViewport(CatViewModel vm, WatchedSiteRule? activeRule) {
    if (vm.browserTabs.isEmpty) {
      return const Center(
        child: Text(
          'All tabs closed. Tap "▸ again" to open YouTube Shorts.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      );
    }

    if (_supportsNativeWebView && _webViewController != null) {
      return ClipRRect(
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(13)),
        child: WebViewWidget(controller: _webViewController!),
      );
    }

    // Desktop / web fallback preview
    return _DesktopTabPreview(
      tab: vm.browserTabs[vm.activeTabIndex],
      activeRule: activeRule,
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop tab preview (no native WebView)
// ---------------------------------------------------------------------------

class _DesktopTabPreview extends StatelessWidget {
  final FocusBrowserTab tab;
  final WatchedSiteRule? activeRule;

  const _DesktopTabPreview({required this.tab, required this.activeRule});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              activeRule != null
                  ? Icons.play_circle_fill
                  : Icons.description_outlined,
              size: 28,
              color: activeRule != null
                  ? Colors.redAccent
                  : Colors.blueGrey[300],
            ),
            const SizedBox(height: 6),
            Text(
              tab.url,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activeRule != null
                  ? 'FocusCat is counting only while this tab is in front of you.\nSwitch to "docs — spec" tab to see the timer pause!'
                  : 'Unwatched work tab — FocusCat timer is paused while you work here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
