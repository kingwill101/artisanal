Map<String, Object?> ghMap(Object? value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, Object?>{};
}

List<Object?> ghList(Object? value) {
  if (value is List) return value.cast<Object?>();
  final map = ghMap(value);
  final nodes = map['nodes'];
  if (nodes is List) return nodes.cast<Object?>();
  return const <Object?>[];
}

String ghString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}

int ghInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int ghCount(Object? value) {
  if (value is List) return value.length;
  final totalCount = ghMap(value)['totalCount'];
  if (totalCount != null) return ghInt(totalCount);
  return ghInt(value);
}

DateTime? ghDate(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

List<String> ghNames(Object? value) {
  return ghList(value)
      .map((item) => ghString(ghMap(item)['name'] ?? ghMap(item)['login']))
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
}
