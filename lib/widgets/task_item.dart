import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;

  final Function(Task) onComplete;

  const TaskItem({super.key, required this.task, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: task.completed,

      title: Text(
        task.title,

        style: TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
        ),
      ),

      onChanged: (value) {
        onComplete(task);
      },
    );
  }
}
