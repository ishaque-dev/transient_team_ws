enum TaskPriority {
  low,
  medium,
  high;

  String get name => toString();
}

enum TaskStatus {
  pending,
  inProgress,
  completed;

  String get name => toString();
}
