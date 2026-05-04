String relativeGithubTime(DateTime? value) {
  if (value == null) return 'updated unknown';
  final delta = DateTime.now().difference(value);
  if (delta.inDays >= 1) return 'updated ${delta.inDays}d ago';
  if (delta.inHours >= 1) return 'updated ${delta.inHours}h ago';
  if (delta.inMinutes >= 1) return 'updated ${delta.inMinutes}m ago';
  return 'updated just now';
}

String shortGithubTime(DateTime value) {
  String two(int input) => input.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}
