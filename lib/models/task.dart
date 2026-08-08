class Task {
  String id;
  String title;
  DateTime? deadline;
  bool completed;
  bool fixed;

  Task({
    required this.id,
    required this.title,
    this.deadline,
    this.completed = false,
    this.fixed = false,
  });
}