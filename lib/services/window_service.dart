import 'dart:io';
import 'dart:ui';

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:window_manager/window_manager.dart';

import '../models/app_settings.dart';

class WindowService {
  Future<void> initialize() async {
    if (!Platform.isMacOS && !Platform.isWindows) return;
    await windowManager.ensureInitialized();
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
}
