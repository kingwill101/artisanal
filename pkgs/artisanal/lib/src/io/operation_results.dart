/// Result of a task operation.
enum TaskResult {
  /// Task completed successfully.
  success,

  /// Task failed.
  failure,

  /// Task was skipped.
  skipped,
}

/// Result of a task group operation.
class TaskGroupResult {
  /// Creates a task group result.
  const TaskGroupResult({
    required this.completed,
    required this.failed,
    required this.skipped,
    this.duration,
  });

  /// Names of successfully completed tasks.
  final List<String> completed;

  /// List of (name, error) pairs for failed tasks.
  final List<(String, Object)> failed;

  /// Names of tasks that were skipped due to prior failures.
  final List<String> skipped;

  /// Total duration of the task group execution.
  final Duration? duration;

  /// Whether all tasks completed successfully.
  bool get success => failed.isEmpty && skipped.isEmpty;

  /// Total number of tasks.
  int get total => completed.length + failed.length + skipped.length;
}

/// Result of a steps workflow operation.
class StepsResult {
  /// Creates a steps result.
  const StepsResult({
    required this.completed,
    required this.failed,
    required this.skipped,
    this.duration,
  });

  /// Names of successfully completed steps.
  final List<String> completed;

  /// List of (name, error) pairs for failed steps.
  final List<(String, Object)> failed;

  /// Names of steps skipped due to prior failures.
  final List<String> skipped;

  /// Total duration of the workflow execution.
  final Duration? duration;

  /// Whether all steps completed successfully.
  bool get success => failed.isEmpty && skipped.isEmpty;

  /// Total number of steps.
  int get total => completed.length + failed.length + skipped.length;
}
