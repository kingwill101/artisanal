/// Operational mode for the OpenCode example.
library;

enum BuildMode { build, plan }

extension BuildModeLabel on BuildMode {
  String get label => switch (this) {
    BuildMode.build => 'Build',
    BuildMode.plan => 'Plan',
  };
}
