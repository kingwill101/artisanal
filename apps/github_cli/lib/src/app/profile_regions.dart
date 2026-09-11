import 'package:artisanal/tui.dart' as tui;
import 'package:devtools_region_profiler/devtools_region_profiler.dart'
    as profiler;

final class GithubCliReplayProfileRegionHook {
  GithubCliReplayProfileRegionHook({this.eventPrefix = 'github_cli.profile'});

  final String eventPrefix;

  String get _startEvent => '$eventPrefix.start';
  String get _stopEvent => '$eventPrefix.stop';

  profiler.ProfileRegionHandle? _activeRegion;

  Future<tui.ReplayEventDirective?> call(tui.ReplayCustomEvent event) async {
    if (event.type == _startEvent) {
      await _start(event);
      return tui.ReplayEventDirective.proceed;
    }
    if (event.type == _stopEvent) {
      await _stop();
      return tui.ReplayEventDirective.proceed;
    }
    return null;
  }

  Future<void> _start(tui.ReplayCustomEvent event) async {
    await _stop();
    final warmupMs = _eventIntField(event, 'warmupMs');
    if (warmupMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: warmupMs));
    }

    final name = _eventField(event, 'name') ?? 'github_cli.replay';
    final attributes = <String, String>{
      'source': 'github_cli',
      for (final entry in event.fields.entries)
        if (entry.key != 'name' && entry.value != null)
          entry.key: entry.value.toString(),
    };

    try {
      _activeRegion = await profiler.startProfileRegion(
        name,
        attributes: attributes,
        options: const profiler.ProfileRegionOptions(
          captureKinds: [profiler.ProfileCaptureKind.cpu],
        ),
      );
    } on profiler.ProfileRegionConfigurationException {
      _activeRegion = null;
    }
  }

  Future<void> _stop() async {
    final region = _activeRegion;
    if (region == null) return;
    _activeRegion = null;
    try {
      await region.stop();
    } on profiler.ProfileRegionConfigurationException {
      // The profiler process may have exited before the replay stream drained.
    }
  }
}

String? _eventField(tui.ReplayCustomEvent event, String name) {
  final value = event.fields[name];
  if (value == null) return null;
  final string = value.toString().trim();
  return string.isEmpty ? null : string;
}

int _eventIntField(tui.ReplayCustomEvent event, String name) {
  final raw = _eventField(event, name);
  if (raw == null) return 0;
  final value = int.tryParse(raw);
  return value == null || value < 0 ? 0 : value;
}
