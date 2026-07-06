import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/layout_widgets.dart';
import 'package:artisanal_widgets/src/widgets/theme/theme.dart';
import 'package:artisanal_widgets/src/widgets/theme_scope.dart';
import 'package:artisanal_widgets/src/widgets/components/component_style.dart';

/// Status of a single step in a [StepIndicator].
enum StepStatus {
  /// Step has not been started.
  pending,

  /// Step is currently active/in-progress.
  active,

  /// Step has been completed successfully.
  completed,

  /// Step encountered an error.
  error,

  /// Step was skipped.
  skipped,
}

/// A single step in a [StepIndicator].
class StepItem {
  const StepItem({
    required this.label,
    this.status = StepStatus.pending,
    this.description,
  });

  /// The step label.
  final String label;

  /// Current status of the step.
  final StepStatus status;

  /// Optional longer description.
  final String? description;

  /// Creates a [StepItem] from a map structure.
  ///
  /// Expected format:
  /// ```json
  /// {"label": "Install", "status": "completed", "description": "..."}
  /// ```
  factory StepItem.fromMap(Map<String, dynamic> map) {
    final statusStr = (map['status'] as String?) ?? 'pending';
    final status = switch (statusStr) {
      'active' => StepStatus.active,
      'completed' => StepStatus.completed,
      'error' => StepStatus.error,
      'skipped' => StepStatus.skipped,
      _ => StepStatus.pending,
    };
    return StepItem(
      label: (map['label'] ?? '') as String,
      status: status,
      description: map['description'] as String?,
    );
  }
}

/// A step-by-step progress indicator widget.
///
/// Renders steps vertically with status icons and connecting lines.
///
/// ```dart
/// StepIndicator(
///   steps: [
///     StepItem(label: 'Install', status: StepStatus.completed),
///     StepItem(label: 'Configure', status: StepStatus.active),
///     StepItem(label: 'Deploy', status: StepStatus.pending),
///   ],
/// )
/// ```
class StepIndicator extends StatelessWidget {
  StepIndicator({required this.steps, this.current, super.key});

  /// The steps to display.
  final List<StepItem> steps;

  /// Index of the current active step (overrides individual step status).
  final int? current;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final children = <Widget>[];

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final effectiveStatus = _resolveStatus(step, i);
      final (icon, iconColor) = _iconForStatus(effectiveStatus, theme);

      final iconStyle = copyStyle(Style())..foreground(iconColor);
      final labelStyle = copyStyle(theme.bodyMedium)
        ..foreground(
          effectiveStatus == StepStatus.active
              ? theme.onSurface
              : (effectiveStatus == StepStatus.completed
                    ? theme.success
                    : theme.muted),
        );

      if (effectiveStatus == StepStatus.active) {
        labelStyle.bold();
      } else if (effectiveStatus == StepStatus.skipped) {
        labelStyle.dim();
      }

      final stepRow = Row(
        gap: 1,
        children: [
          Text(icon, style: iconStyle),
          Text(step.label, style: labelStyle),
        ],
      );

      children.add(stepRow);

      if (step.description != null && step.description!.isNotEmpty) {
        final descStyle = copyStyle(theme.bodySmall)..foreground(theme.muted);
        children.add(
          Row(
            gap: 0,
            children: [
              Text('  ', style: descStyle),
              Text(step.description!, style: descStyle),
            ],
          ),
        );
      }

      // Add connector line between steps.
      if (i < steps.length - 1) {
        final connectorColor = effectiveStatus == StepStatus.completed
            ? theme.success
            : theme.border;
        final connectorStyle = copyStyle(Style())..foreground(connectorColor);
        children.add(Text('│', style: connectorStyle));
      }
    }

    return Column(gap: 0, children: children);
  }

  StepStatus _resolveStatus(StepItem step, int index) {
    if (current == null) return step.status;
    if (index < current!) return StepStatus.completed;
    if (index == current!) return StepStatus.active;
    return StepStatus.pending;
  }

  (String, Color) _iconForStatus(StepStatus status, Theme theme) {
    return switch (status) {
      StepStatus.pending => ('○', theme.muted),
      StepStatus.active => ('●', theme.primary),
      StepStatus.completed => ('✓', theme.success),
      StepStatus.error => ('✗', theme.error),
      StepStatus.skipped => ('⊘', theme.muted),
    };
  }
}
