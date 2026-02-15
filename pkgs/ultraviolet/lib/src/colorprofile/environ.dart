library;

bool _parseBool(String? value) {
  if (value == null) return false;
  final v = value.trim().toLowerCase();
  if (v.isEmpty) return false;
  return switch (v) {
    '1' || 't' || 'true' || 'y' || 'yes' || 'on' => true,
    '0' || 'f' || 'false' || 'n' || 'no' || 'off' => false,
    _ => false,
  };
}

bool envNoColor(Map<String, String> env) {
  if (!env.containsKey('NO_COLOR')) return false;
  final raw = env['NO_COLOR'];
  // Presence is generally treated as "enabled" for NO_COLOR, but allow explicit
  // false-y values to opt back in.
  if (raw == null || raw.trim().isEmpty) return true;
  return _parseBool(raw);
}

bool cliColor(Map<String, String> env) => _parseBool(env['CLICOLOR']);

bool cliColorForced(Map<String, String> env) =>
    _parseBool(env['CLICOLOR_FORCE']);

bool colorTerm(Map<String, String> env) {
  final v = (env['COLORTERM'] ?? '').trim().toLowerCase();
  return v == 'truecolor' || v == '24bit' || v == 'yes' || v == 'true';
}
