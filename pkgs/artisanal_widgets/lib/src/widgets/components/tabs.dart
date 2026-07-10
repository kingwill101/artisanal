import 'package:artisanal/widgets.dart';

/// A tab item for use with [Tabs].
///
/// An optional icon widget can be displayed alongside the tab label text.
class TabItem {
  const TabItem(this.label, {this.icon, this.enabled = true});

  final String label;
  final Widget? icon;
  final bool enabled;
}

/// A horizontal tab bar for switching between views.
///
/// The [Tabs] widget displays a row of tab buttons. The [index] property
/// controls which tab is currently selected. Use [onChanged] to receive
/// notifications when the user selects a different tab.
///
/// Each [TabItem] can have an optional icon displayed alongside its label.
/// Disabled tabs via [TabItem.enabled] are not clickable.
///
/// Example:
/// ```dart
/// Tabs(
///   tabs: [
///     TabItem(label: 'Overview'),
///     TabItem(label: 'Settings', icon: Icon('⚙')),
///   ],
///   index: _selectedTab,
///   onChanged: (i) => setState(() => _selectedTab = i),
/// )
/// ```
class Tabs extends StatelessWidget {
  Tabs({
    required this.tabs,
    required this.index,
    this.onChanged,
    this.gap = 1,
    this.size = ButtonSize.small,
    super.key,
  });

  final List<TabItem> tabs;
  final int index;
  final ValueCmdCallback<int>? onChanged;
  final int gap;
  final ButtonSize size;

  @override
  Widget build(BuildContext context) {
    return Row(
      gap: gap,
      children: [for (var i = 0; i < tabs.length; i++) _tabButton(tabs[i], i)],
    );
  }

  Widget _tabButton(TabItem item, int tabIndex) {
    final selected = tabIndex == index;
    final label = item.icon == null
        ? Text(item.label)
        : Row(gap: 1, children: [item.icon!, Text(item.label)]);
    return Button(
      child: label,
      size: size,
      enabled: item.enabled,
      variant: selected ? ButtonVariant.primary : ButtonVariant.ghost,
      onPressed: onChanged == null
          ? null
          : () {
              return onChanged?.call(tabIndex);
            },
    );
  }
}
