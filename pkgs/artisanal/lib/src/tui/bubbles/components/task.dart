import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// Task status values.
enum TaskStatus { success, failure, skipped, running }

/// A task status component (Laravel-style).
///
/// ```dart
/// TaskComponent(
///   description: 'Running migrations',
///   status: TaskStatus.success,
/// ).render();
/// ```
class TaskComponent extends DisplayComponent {
  const TaskComponent({
    required this.description,
    required this.status,
    this.fillChar = '.',
    this.indent = 2,
    this.renderConfig = const RenderConfig(),
  });

  final String description;
  final TaskStatus status;
  final String fillChar;
  final int indent;
  final RenderConfig renderConfig;

  @override
  String render() {
    final style = renderConfig.configureStyle(Style());
    final statusText = switch (status) {
      TaskStatus.success =>
        style.foreground(Colors.success).bold().render('DONE'),
      TaskStatus.failure =>
        style.foreground(Colors.error).bold().render('FAIL'),
      TaskStatus.skipped =>
        style.foreground(Colors.warning).bold().render('SKIP'),
      TaskStatus.running => style.foreground(Colors.info).bold().render('...'),
    };

    final descLen = Style.visibleLength(description);
    final statusLen = 4; // DONE/FAIL/SKIP
    final available =
        renderConfig.terminalWidth - indent - descLen - statusLen - 2;
    final fill = available > 0 ? ' ${fillChar * available} ' : ' ';

    return '${' ' * indent}$description$fill$statusText';
  }
}
