import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../models/app_settings.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/window_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.tasks, required this.windows});
  final TaskService tasks;
  final WindowService windows;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    widget.tasks.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.tasks.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => mounted ? setState(() {}) : null;

  @override
  Widget build(BuildContext context) {
    final settings = widget.tasks.settings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: settings.transparentBackground
              ? Colors.transparent
              : Color(settings.backgroundColor),
        ),
        child: Stack(
          children: [
            DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 14 * settings.fontScale,
                color: Color(settings.textColor),
              ),
              child: Column(
                children: [
                  _TitleBar(
                    settings: settings,
                    onSettings: _showSettings,
                    onAdd: _showAddDialog,
                    onLock: _toggleLock,
                  ),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: settings.mousePassthrough,
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            constraints.maxWidth < 620
                            ? ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  _fixedPanel(),
                                  const SizedBox(height: 16),
                                  _temporaryPanel(),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: _fixedPanel()),
                                  const VerticalDivider(width: 1),
                                  Expanded(child: _temporaryPanel()),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fixedPanel() => _Panel(
    title: '固定事项',
    icon: Icons.repeat_rounded,
    trailing: Text(
      '${widget.tasks.fixedCompleted}/${widget.tasks.fixedTasks.length}',
      style: const TextStyle(color: Color(0xff756d84)),
    ),
    child: Column(
      children: [
        LinearProgressIndicator(
          value: widget.tasks.fixedTasks.isEmpty
              ? 0
              : widget.tasks.fixedCompleted / widget.tasks.fixedTasks.length,
          minHeight: 6,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 12),
        if (widget.tasks.fixedTasks.isEmpty)
          const _EmptyState('还没有固定事项')
        else
          ...widget.tasks.fixedTasks.map(
            (task) => _TaskTile(
              task: task,
              textColor: Color(widget.tasks.settings.textColor),
              onToggle: () => widget.tasks.toggleFixed(task),
              onDelete: () => widget.tasks.deleteTask(task),
            ),
          ),
      ],
    ),
  );

  Widget _temporaryPanel() {
    final groups = <String, List<Task>>{};
    for (final task in widget.tasks.temporaryTasks) {
      groups.putIfAbsent(_deadlineGroup(task.deadline), () => []).add(task);
    }
    return _Panel(
      title: '临时事项',
      icon: Icons.bolt_rounded,
      child: groups.isEmpty
          ? const _EmptyState('清空啦，享受片刻轻松')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groups.entries
                  .expand(
                    (entry) => [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 5),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xff756d84),
                          ),
                        ),
                      ),
                      ...entry.value.map(
                        (task) => _TaskTile(
                          task: task,
                          textColor: Color(widget.tasks.settings.textColor),
                          onToggle: () => widget.tasks.completeTemporary(task),
                          onDelete: () => widget.tasks.deleteTask(task),
                        ),
                      ),
                    ],
                  )
                  .toList(),
            ),
    );
  }

  String _deadlineGroup(DateTime? date) {
    if (date == null) return '未设期限';
    final now = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(date);
    if (!day.isAfter(now)) return day == now ? '今日' : '已逾期';
    if (day.difference(now).inDays < 7) return '本周';
    if (day.year == now.year && day.month == now.month) return '本月';
    if (day.year == now.year) return '本年';
    return '${day.year} 年';
  }

  Future<void> _showAddDialog() async {
    final type = await showModalBottomSheet<TaskKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('添加固定事项'),
              onTap: () => Navigator.pop(context, TaskKind.fixed),
            ),
            ListTile(
              leading: const Icon(Icons.bolt),
              title: const Text('添加临时事项'),
              onTap: () => Navigator.pop(context, TaskKind.temporary),
            ),
          ],
        ),
      ),
    );
    if (type != null && mounted) {
      await showDialog(
        context: context,
        builder: (_) => _AddTaskDialog(type: type, tasks: widget.tasks),
      );
    }
  }

  Future<void> _showSettings() async {
    widget.windows.setSettingsOpen(true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SettingsSheet(tasks: widget.tasks, windows: widget.windows),
    );
    widget.windows.setSettingsOpen(false);
    await widget.windows.apply(widget.tasks.settings);
  }

  Future<void> _toggleLock() async {
    final next = widget.tasks.settings.copyWith(
      mousePassthrough: !widget.tasks.settings.mousePassthrough,
    );
    await widget.tasks.updateSettings(next);
    await widget.windows.apply(next);
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.settings,
    required this.onSettings,
    required this.onAdd,
    required this.onLock,
  });
  final AppSettings settings;
  final VoidCallback onSettings;
  final VoidCallback onAdd;
  final VoidCallback onLock;
  @override
  Widget build(BuildContext context) => DragToMoveArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xff8064c7)),
          const SizedBox(width: 8),
          const Text(
            'Luna To-Do',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (settings.mousePassthrough)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.lock_outline,
                size: 17,
                color: Color(0xff8064c7),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: '添加事项',
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            tooltip: '设置',
            onPressed: onSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: settings.mousePassthrough ? '解锁内容区' : '锁定内容区',
            onPressed: onLock,
            icon: Icon(
              settings.mousePassthrough
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
            ),
          ),
          IconButton(
            tooltip: '最小化',
            onPressed: windowManager.minimize,
            icon: const Icon(Icons.minimize_rounded),
          ),
          IconButton(
            tooltip: '关闭',
            onPressed: windowManager.close,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xff8064c7)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Center(
      child: Text(text, style: const TextStyle(color: Color(0xff928a9f))),
    ),
  );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.textColor,
    required this.onToggle,
    required this.onDelete,
  });
  final Task task;
  final Color textColor;
  final VoidCallback onToggle, onDelete;
  @override
  Widget build(BuildContext context) {
    final isOverdue =
        task.kind == TaskKind.temporary &&
        task.deadline != null &&
        DateUtils.dateOnly(
          task.deadline!,
        ).isBefore(DateUtils.dateOnly(DateTime.now()));
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Row(
              children: [
                Checkbox(value: task.completed, onChanged: (_) => onToggle()),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.completed
                              ? const Color(0xff928a9f)
                              : textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.kind == TaskKind.fixed
                            ? task.recurrence!.label
                            : _dateText(task.deadline),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue
                              ? Colors.red.shade400
                              : textColor.withValues(alpha: .65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xff928a9f),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateText(DateTime? value) =>
      value == null ? '未设期限' : '${value.year}/${value.month}/${value.day}';
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog({required this.type, required this.tasks});
  final TaskKind type;
  final TaskService tasks;
  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final text = TextEditingController();
  Recurrence recurrence = Recurrence.daily;
  DateTime deadline = DateTime.now();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.type == TaskKind.fixed ? '添加固定事项' : '添加临时事项'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: text,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '事项内容',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.type == TaskKind.fixed)
          DropdownButtonFormField(
            initialValue: recurrence,
            decoration: const InputDecoration(
              labelText: '重复周期',
              border: OutlineInputBorder(),
            ),
            items: Recurrence.values
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(value.label)),
                )
                .toList(),
            onChanged: (value) => setState(() => recurrence = value!),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('截止日期'),
            subtitle: Text(
              '${deadline.year}/${deadline.month}/${deadline.day}',
            ),
            onTap: () async {
              final value = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: deadline,
              );
              if (value != null) setState(() => deadline = value);
            },
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () async {
          if (text.text.trim().isEmpty) return;
          if (widget.type == TaskKind.fixed) {
            await widget.tasks.addFixed(text.text, recurrence);
          } else {
            await widget.tasks.addTemporary(text.text, deadline);
          }
          if (context.mounted) Navigator.pop(context);
        },
        child: const Text('添加'),
      ),
    ],
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.tasks, required this.windows});
  final TaskService tasks;
  final WindowService windows;
  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late AppSettings settings;
  @override
  void initState() {
    super.initState();
    settings = widget.tasks.settings;
  }

  Future<void> _save(AppSettings next) async {
    setState(() => settings = next);
    await widget.tasks.updateSettings(next);
    await widget.windows.apply(next);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: settings.transparentBackground
              ? Colors.transparent
              : Color(settings.backgroundColor),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: Color(settings.textColor)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      '设置中心',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '关闭设置',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _slider(
                  '页面透明度',
                  settings.opacity,
                  0,
                  1,
                  (v) => _save(settings.copyWith(opacity: v)),
                ),
                const SizedBox(height: 8),
                const Text('背景', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final color in const [
                      0xfffcfbff,
                      0xfffff7ed,
                      0xfff0fdf4,
                      0xffeff6ff,
                      0xfffdf2f8,
                      0xff1f2937,
                    ])
                      ChoiceChip(
                        label: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xff928a9f)),
                          ),
                        ),
                        selected:
                            !settings.transparentBackground &&
                            settings.backgroundColor == color,
                        onSelected: (_) => _save(
                          settings.copyWith(
                            backgroundColor: color,
                            transparentBackground: false,
                          ),
                        ),
                      ),
                    ChoiceChip(
                      avatar: const Icon(Icons.layers_clear_outlined, size: 18),
                      label: const Text('无背景'),
                      selected: settings.transparentBackground,
                      onSelected: (_) =>
                          _save(settings.copyWith(transparentBackground: true)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '文字颜色',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final color in const [
                      0xff111827,
                      0xff1f2937,
                      0xff374151,
                      0xff4c1d95,
                      0xff0f766e,
                      0xff9f1239,
                    ])
                      ChoiceChip(
                        label: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xff928a9f)),
                          ),
                        ),
                        selected: settings.textColor == color,
                        onSelected: (_) =>
                            _save(settings.copyWith(textColor: color)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _slider(
                  '字体大小',
                  settings.fontScale,
                  .8,
                  1.4,
                  (v) => _save(settings.copyWith(fontScale: v)),
                ),
                _slider(
                  '窗口宽度',
                  settings.windowWidth,
                  480,
                  1200,
                  (v) => _save(settings.copyWith(windowWidth: v)),
                ),
                _slider(
                  '窗口高度',
                  settings.windowHeight,
                  400,
                  1000,
                  (v) => _save(settings.copyWith(windowHeight: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('始终置顶'),
                  value: settings.alwaysOnTop,
                  onChanged: (v) => _save(settings.copyWith(alwaysOnTop: v)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    settings.mousePassthrough
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                  ),
                  title: const Text('锁定内容区'),
                  subtitle: const Text('请使用主页右下角按钮锁定；锁定后通过系统托盘解除'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('提醒'),
                  subtitle: const Text('保留提醒开关，V1.0 不发送系统通知'),
                  value: settings.remindersEnabled,
                  onChanged: (v) =>
                      _save(settings.copyWith(remindersEnabled: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('开机启动'),
                  value: settings.launchAtStartup,
                  onChanged: (v) =>
                      _save(settings.copyWith(launchAtStartup: v)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _slider(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$title  ${value.toStringAsFixed(value < 10 ? 2 : 0)}'),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    ],
  );
}
