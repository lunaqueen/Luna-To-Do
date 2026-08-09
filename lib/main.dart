import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'services/task_service.dart';
import 'services/storage.dart';
import 'services/window_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final windows = WindowService();
  await windows.initialize();
  final tasks = TaskService(StorageService());
  await tasks.load();
  windows.setUnlockHandler(
    () =>
        tasks.updateSettings(tasks.settings.copyWith(mousePassthrough: false)),
  );
  await windows.apply(tasks.settings);
  runApp(LunaTodo(tasks: tasks, windows: windows));
}

class LunaTodo extends StatelessWidget {
  const LunaTodo({super.key, required this.tasks, required this.windows});
  final TaskService tasks;
  final WindowService windows;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Luna To-Do',
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xff8064c7),
    ),
    home: HomePage(tasks: tasks, windows: windows),
  );
}
