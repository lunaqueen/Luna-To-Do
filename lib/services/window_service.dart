import 'dart:io';

import 'package:flutter/services.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../models/app_settings.dart';

class WindowService with TrayListener {
  Future<void> Function()? _onUnlock;

  void setUnlockHandler(Future<void> Function() handler) {
    _onUnlock = handler;
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
    final iconPath = await _copyTrayIcon();
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

  Future<String> _copyTrayIcon() async {
    final isWindows = Platform.isWindows;
    final asset = isWindows
        ? 'windows/runner/resources/app_icon.ico'
        : 'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png';
    final extension = isWindows ? 'ico' : 'png';
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/luna_tray_icon.$extension');
    if (!await file.exists()) {
      final data = await rootBundle.load(asset);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file.path;
  }

  Future<void> apply(AppSettings settings) async {
    if (!Platform.isMacOS && !Platform.isWindows) return;
    await windowManager.setOpacity(settings.opacity);
    await windowManager.setAlwaysOnTop(settings.alwaysOnTop);
    await windowManager.setIgnoreMouseEvents(
      settings.mousePassthrough,
      forward: true,
    );
    await windowManager.setSize(
      Size(settings.windowWidth, settings.windowHeight),
    );
    await _setLaunchAtStartup(settings.launchAtStartup);
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
