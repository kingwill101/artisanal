/// Internal logging for the UV subsystem.
///
/// Defines the [Logger] interface used for debugging and tracing internal
/// Ultraviolet operations.
///
/// {@category Ultraviolet}
/// {@subCategory Utilities}
library;

/// Logger is a simple logger interface for Ultraviolet internals.
///
abstract class Logger {
  void printf(String format, [List<Object?>? args]);
}

/// A logger that does nothing.
class NullLogger implements Logger {
  const NullLogger();
  @override
  void printf(String format, [List<Object?>? args]) {}
}
