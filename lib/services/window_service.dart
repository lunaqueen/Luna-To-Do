import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../models/app_settings.dart';

class WindowService with TrayListener {
  Future<void> Function()? _onUnlock;
  Timer? _hitTestTimer;
  bool _locked = false;
  bool _toolbarInteractive = false;
  bool _settingsOpen = false;

  void setUnlockHandler(Future<void> Function() handler) {
    _onUnlock = handler;
  }

  void setSettingsOpen(bool open) {
    _settingsOpen = open;
    if (open && _locked) {
      windowManager.setIgnoreMouseEvents(false);
    }
  }

  Future<void> initialize() async {
    if (!Platform.isMacOS && !Platform.isWindows) return;
    await windowManager.ensureInitialized();
    trayManager.addListener(this);
    const options = WindowOptions(
      size: Size(760, 600),
      minimumSize: Size(480, 400),
      center: true,
      backgroundColor: Color(0x00000000),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setAsFrameless();
      await windowManager.show();
      await windowManager.focus();
    });
    await _setupTray();
  }

  Future<void> _setupTray() async {
    // tray_manager expects a Flutter asset key. On Windows it resolves that
    // key within `data/flutter_assets`; on macOS it loads it via rootBundle.
    final iconPath = Platform.isWindows
        ? 'windows/runner/resources/app_icon.ico'
        : 'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png';
    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('Luna To-Do');
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'unlock_window', label: '解除窗口锁定'),
          MenuItem(key: 'show_window', label: '显示 Luna To-Do'),
          MenuItem.separator(),
          MenuItem(key: 'quit_app', label: '退出'),
        ],
      ),
    );
  }

  Future<void> apply(AppSettings settings) async {
    if (!Platform.isMacOS && !Platform.isWindows) return;
    // Keep the native window fully opaque so text never fades with the
    // background. The panel applies opacity only to its own background.
    await windowManager.setOpacity(1.0);
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setHasShadow(false);
    await windowManager.setAlwaysOnTop(settings.alwaysOnTop);
    // Native click-through is intentional while locked: other apps remain
    // usable underneath the always-on-top todo. Unlock from the system tray.
    _locked = settings.mousePassthrough;
    if (_locked && !_settingsOpen) {
      await windowManager.setIgnoreMouseEvents(true);
      _startToolbarHitTest();
    } else {
      _stopToolbarHitTest();
      await windowManager.setIgnoreMouseEvents(false);
    }
    await windowManager.setSize(
      Size(settings.windowWidth, settings.windowHeight),
    );
    await _setLaunchAtStartup(settings.launchAtStartup);
  }

  void _startToolbarHitTest() {
    _hitTestTimer ??= Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateToolbarHitTest(),
    );
  }

  void _stopToolbarHitTest() {
    _hitTestTimer?.cancel();
    _hitTestTimer = null;
    _toolbarInteractive = false;
  }

  Future<void> _updateToolbarHitTest() async {
    if (!_locked || _settingsOpen) return;
    final position = await windowManager.getPosition();
    final size = await windowManager.getSize();
    final cursor = await screenRetriever.getCursorScreenPoint();
    final inToolbar =
        cursor.dx >= position.dx &&
        cursor.dx <= position.dx + size.width &&
        cursor.dy >= position.dy &&
        cursor.dy <= position.dy + 78;
    if (inToolbar == _toolbarInteractive) return;
    _toolbarInteractive = inToolbar;
    await windowManager.setIgnoreMouseEvents(!inToolbar);
  }

  Future<void> _setLaunchAtStartup(bool enabled) async {
    try {
      launchAtStartup.setup(
        appName: 'Luna To-Do',
        appPath: Platform.resolvedExecutable,
      );
      enabled
          ? await launchAtStartup.enable()
          : await launchAtStartup.disable();
    } catch (_) {
      /* Platform setup can be unavailable during development. */
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'unlock_window':
        _locked = false;
        _stopToolbarHitTest();
        await windowManager.setIgnoreMouseEvents(false);
        await _onUnlock?.call();
      case 'show_window':
        await windowManager.show();
        await windowManager.focus();
      case 'quit_app':
        await windowManager.destroy();
    }
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }
}
