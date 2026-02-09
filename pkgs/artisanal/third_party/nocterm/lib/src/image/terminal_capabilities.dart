import 'dart:async';
import 'dart:io';

/// Represents the capabilities of the terminal.
///
/// This class detects and stores information about what features
/// the current terminal supports, including Sixel graphics.
class TerminalCapabilities {
  /// Whether the terminal supports Sixel graphics.
  bool supportsSixel;

  /// Whether the terminal supports true color (24-bit) mode.
  bool supportsTrueColor;

  /// Whether the terminal supports 256 colors.
  bool supports256Colors;

  /// The terminal type as reported by TERM environment variable.
  String? termType;

  /// Creates a new TerminalCapabilities instance.
  TerminalCapabilities({
    this.supportsSixel = false,
    this.supportsTrueColor = false,
    this.supports256Colors = false,
    this.termType,
  });

  /// Detects terminal capabilities by querying the terminal.
  ///
  /// Sends DA1 (Device Attributes) escape sequence and parses the response
  /// to determine supported features.
  ///
  /// The DA1 response format is: CSI ? Ps ; Ps ; ... c
  /// Where Ps values indicate capabilities:
  /// - 4: Sixel graphics supported
  /// - 22: 256 colors supported
  ///
  /// Parameters:
  /// - [timeout]: How long to wait for terminal response (default 100ms)
  /// - [stdinStream]: Optional stdin stream for testing
  /// - [stdoutSink]: Optional stdout for testing
  ///
  /// Returns a [TerminalCapabilities] instance with detected features.
  static Future<TerminalCapabilities> detect({
    Duration timeout = const Duration(milliseconds: 100),
    Stream<List<int>>? stdinStream,
    IOSink? stdoutSink,
  }) async {
    final capabilities = TerminalCapabilities();

    // Get TERM environment variable
    capabilities.termType = Platform.environment['TERM'];

    // Check for known sixel-supporting terminals by TERM
    final term = capabilities.termType?.toLowerCase() ?? '';
    if (_isSixelTermByName(term)) {
      capabilities.supportsSixel = true;
    }

    // Check for 256 color / truecolor support from TERM
    if (term.contains('256color') || term.contains('truecolor')) {
      capabilities.supports256Colors = true;
    }
    if (term.contains('truecolor') ||
        Platform.environment['COLORTERM'] == 'truecolor') {
      capabilities.supportsTrueColor = true;
    }

    // Try to query terminal directly for more accurate detection
    try {
      final detected = await _queryDA1(
        timeout: timeout,
        stdinStream: stdinStream,
        stdoutSink: stdoutSink,
      );

      if (detected != null) {
        // Merge detected capabilities (only upgrade, don't downgrade)
        if (detected.supportsSixel) {
          capabilities.supportsSixel = true;
        }
        if (detected.supports256Colors) {
          capabilities.supports256Colors = true;
        }
      }
    } catch (_) {
      // Query failed, fall back to name-based detection
    }

    return capabilities;
  }

  /// Checks if terminal name indicates Sixel support.
  static bool _isSixelTermByName(String term) {
    // Known Sixel-supporting terminals
    const sixelTerms = [
      'xterm', // Recent versions support sixel
      'mlterm',
      'yaft',
      'foot',
      'contour',
      'wezterm',
      'mintty',
      'sixel',
    ];

    for (final sixelTerm in sixelTerms) {
      if (term.contains(sixelTerm)) {
        return true;
      }
    }

    return false;
  }

  /// Queries the terminal using DA1 (Primary Device Attributes).
  ///
  /// Sends ESC[c and parses the response to detect capabilities.
  static Future<TerminalCapabilities?> _queryDA1({
    required Duration timeout,
    Stream<List<int>>? stdinStream,
    IOSink? stdoutSink,
  }) async {
    final effectiveStdin = stdinStream ?? _getRawStdin();
    final IOSink? effectiveStdout;
    if (stdoutSink != null) {
      effectiveStdout = stdoutSink;
    } else if (Platform.isWindows) {
      effectiveStdout = null;
    } else {
      effectiveStdout = stdout;
    }

    if (effectiveStdin == null || effectiveStdout == null) {
      return null;
    }

    // Send DA1 query: ESC [ c
    const da1Query = '\x1b[c';
    effectiveStdout.write(da1Query);
    await effectiveStdout.flush();

    // Read response with timeout
    final completer = Completer<String>();
    final buffer = StringBuffer();
    late StreamSubscription<List<int>> subscription;

    subscription = effectiveStdin.listen(
      (data) {
        buffer.write(String.fromCharCodes(data));
        final response = buffer.toString();

        // DA1 response ends with 'c'
        if (response.contains('c')) {
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete(response);
          }
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    try {
      final response = await completer.future.timeout(timeout);
      return _parseDA1Response(response);
    } on TimeoutException {
      subscription.cancel();
      return null;
    } catch (_) {
      subscription.cancel();
      return null;
    }
  }

  /// Gets raw stdin stream if available.
  static Stream<List<int>>? _getRawStdin() {
    try {
      if (stdin.hasTerminal) {
        return stdin;
      }
    } catch (_) {
      // Not a terminal
    }
    return null;
  }

  /// Parses DA1 response to extract capabilities.
  ///
  /// Response format: ESC [ ? Ps ; Ps ; ... c
  /// Where Ps values indicate capabilities:
  /// - 4: Sixel graphics
  /// - 22: 256 colors
  static TerminalCapabilities? _parseDA1Response(String response) {
    // Find the DA1 response pattern: ESC [ ? ... c
    final match = RegExp(r'\x1b\[\?([0-9;]+)c').firstMatch(response);
    if (match == null) {
      return null;
    }

    final params = match.group(1)!.split(';').map(int.tryParse).toList();
    final capabilities = TerminalCapabilities();

    for (final param in params) {
      if (param == null) continue;

      switch (param) {
        case 4:
          // Sixel graphics supported
          capabilities.supportsSixel = true;
        case 22:
          // 256 colors supported
          capabilities.supports256Colors = true;
      }
    }

    return capabilities;
  }

  /// Creates a copy of this capabilities instance.
  TerminalCapabilities copyWith({
    bool? supportsSixel,
    bool? supportsTrueColor,
    bool? supports256Colors,
    String? termType,
  }) {
    return TerminalCapabilities(
      supportsSixel: supportsSixel ?? this.supportsSixel,
      supportsTrueColor: supportsTrueColor ?? this.supportsTrueColor,
      supports256Colors: supports256Colors ?? this.supports256Colors,
      termType: termType ?? this.termType,
    );
  }

  @override
  String toString() {
    return 'TerminalCapabilities('
        'supportsSixel: $supportsSixel, '
        'supportsTrueColor: $supportsTrueColor, '
        'supports256Colors: $supports256Colors, '
        'termType: $termType)';
  }
}
