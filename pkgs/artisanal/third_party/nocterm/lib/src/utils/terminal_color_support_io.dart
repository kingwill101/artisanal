import 'dart:io';

import 'package:nocterm/src/utils/terminal_color_support_internal.dart';

bool? _overrideTruecolor;
bool? _cachedTruecolor;

bool supportsTruecolor() {
  if (_overrideTruecolor != null) {
    return _overrideTruecolor!;
  }
  return _cachedTruecolor ??= detectTruecolorFromEnv(Platform.environment);
}

void setSupportsTruecolorForTesting(bool? value) {
  _overrideTruecolor = value;
  _cachedTruecolor = null;
}
