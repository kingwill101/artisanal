/// Verbosity levels for console output.
///
/// Used to control how much output is displayed based on the `-v` flag.
///
/// - `quiet`: No output (except errors)
/// - `normal`: Standard output
/// - `verbose`: More detailed output (-v)
/// - `veryVerbose`: Even more details (-vv)
/// - `debug`: Maximum verbosity (-vvv)
enum Verbosity {
  /// No output (except errors). Triggered by `-q` or `--quiet`.
  quiet,

  /// Standard output level.
  normal,

  /// Verbose output. Triggered by `-v`.
  verbose,

  /// Very verbose output. Triggered by `-vv`.
  veryVerbose,

  /// Debug-level output. Triggered by `-vvv`.
  debug,
}
