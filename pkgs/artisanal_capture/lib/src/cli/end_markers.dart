/// An existence-only substring index for a scenario's END markers.
///
/// Failure links handle overlaps without rescanning the captured frame for
/// each marker. A per-search disjoint set skips terminal outputs already found,
/// so repeated matches do not repeatedly traverse long suffix-output chains.
final class EndMarkerMatcher {
  EndMarkerMatcher(Iterable<String> patterns)
    : markers = _boundedPatterns(patterns) {
    for (final marker in markers) {
      var state = 0;
      for (final unit in marker.codeUnits) {
        state = _next[state][unit] ??= _addNode();
      }
      _output[state] = marker;
    }
    final queue = <int>[..._next[0].values];
    for (var offset = 0; offset < queue.length; offset++) {
      final state = queue[offset];
      for (final edge in _next[state].entries) {
        final child = edge.value;
        queue.add(child);
        var fallback = _fail[state];
        while (fallback != 0 && !_next[fallback].containsKey(edge.key)) {
          fallback = _fail[fallback];
        }
        _fail[child] = _next[fallback][edge.key] ?? 0;
        _outputLink[child] = _output[_fail[child]] != null
            ? _fail[child]
            : _outputLink[_fail[child]];
      }
    }
  }

  factory EndMarkerMatcher.fromSource(String source) {
    return EndMarkerMatcher(
      _markerPattern.allMatches(source).map((match) => match.group(0)!),
    );
  }

  static List<String> _boundedPatterns(Iterable<String> patterns) {
    final markers = <String>{};
    var keyBytes = 0;
    for (final pattern in patterns) {
      if (pattern.isEmpty) {
        throw const FormatException('An END marker is empty.');
      }
      if (markers.add(pattern)) {
        keyBytes += pattern.length * 2;
        if (keyBytes > maxPatternBytes) {
          throw const FormatException(
            'END marker pattern text exceeds 256 KiB.',
          );
        }
      }
      if (markers.length > maxMarkers) {
        throw const FormatException(
          'Scenario exceeds 10000 distinct END markers.',
        );
      }
    }
    return List.unmodifiable(markers);
  }

  static const maxMarkers = 10000;
  // Each state owns a map, so an entry-count bound alone is not sufficient.
  // Keep both the graph and its retained UTF-16 pattern text modest.
  static const maxNodes = 65536;
  static const maxPatternBytes = 256 * 1024;
  static final _markerPattern = RegExp(r'^END_[A-Z0-9_]+$', multiLine: true);

  final List<String> markers;
  final _next = <Map<int, int>>[{}];
  final _fail = <int>[0];
  final _output = <String?>[null];
  final _outputLink = <int>[-1];

  int _addNode() {
    if (_next.length >= maxNodes) {
      throw const FormatException(
        'END marker matcher exceeded its resource limit.',
      );
    }
    _next.add({});
    _fail.add(0);
    _output.add(null);
    _outputLink.add(-1);
    return _next.length - 1;
  }

  Set<String> findIn(String text) {
    final found = <String>{};
    if (markers.isEmpty) return found;
    final unseen = List<int>.generate(
      _next.length,
      (i) => _output[i] != null ? i : _outputLink[i],
    );
    int findUnseen(int node) {
      var root = node;
      while (root >= 0 && unseen[root] != root) {
        root = unseen[root];
      }
      while (node >= 0 && unseen[node] != node) {
        final next = unseen[node];
        unseen[node] = root;
        node = next;
      }
      return root;
    }

    var state = 0;
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      while (state != 0 && !_next[state].containsKey(unit)) {
        state = _fail[state];
      }
      state = _next[state][unit] ?? 0;
      var terminal = findUnseen(state);
      while (terminal >= 0) {
        found.add(_output[terminal]!);
        unseen[terminal] = findUnseen(_outputLink[terminal]);
        terminal = unseen[terminal];
      }
      if (found.length == markers.length) break;
    }
    return found;
  }
}
