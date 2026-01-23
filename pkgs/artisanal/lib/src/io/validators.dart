import 'package:acanthis/acanthis.dart';

// Re-export acanthis for advanced usage
export 'package:acanthis/acanthis.dart';

/// Built-in validators for input prompts using Acanthis.
///
/// Provides two APIs:
/// 1. Simple function validators for use with `io.ask(validator: ...)`
/// 2. Acanthis schemas for more complex validation
///
/// ```dart
/// // Simple function validator
/// final name = io.ask(
///   'Email',
///   validator: Validators.email(),
/// );
///
/// // Using Acanthis schema directly
/// final schema = string().email().min(5);
/// final result = schema.tryParse(input);
/// ```
class Validators {
  Validators._();

  // ─────────────────────────────────────────────────────────────────────────────
  // String Validators
  // ─────────────────────────────────────────────────────────────────────────────

  /// Validates that the input is not empty.
  static String? Function(String) required({
    String message = 'This field is required.',
  }) {
    final schema = string().notEmpty(message: message);
    return (value) => _validate(schema, value);
  }

  /// Validates that the input is a valid email address.
  static String? Function(String) email({
    String message = 'Please enter a valid email address.',
  }) {
    final schema = string().email(message: message);
    return (value) {
      if (value.trim().isEmpty) return null; // Optional by default
      return _validate(schema, value);
    };
  }

  /// Validates that the input is a valid URL.
  static String? Function(String) url({
    String message = 'Please enter a valid URL.',
  }) {
    final schema = string().url(message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input is a valid URI.
  static String? Function(String) uri({
    String message = 'Please enter a valid URI.',
  }) {
    final schema = string().uri(message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates the minimum length of input.
  static String? Function(String) minLength(int length, {String? message}) {
    final schema = string().min(
      length,
      message: message ?? 'Must be at least $length characters.',
    );
    return (value) => _validate(schema, value);
  }

  /// Validates the maximum length of input.
  static String? Function(String) maxLength(int length, {String? message}) {
    final schema = string().max(
      length,
      message: message ?? 'Must be at most $length characters.',
    );
    return (value) => _validate(schema, value);
  }

  /// Validates exact length of input.
  static String? Function(String) exactLength(int len, {String? message}) {
    final schema = string().length(
      len,
      message: message ?? 'Must be exactly $len characters.',
    );
    return (value) => _validate(schema, value);
  }

  /// Validates that the input matches a regex pattern.
  static String? Function(String) pattern(
    Pattern regex, {
    String message = 'Invalid format.',
  }) {
    final schema = string().pattern(regex, message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input contains only letters.
  static String? Function(String) letters({
    bool strict = true,
    String message = 'Only letters are allowed.',
  }) {
    final schema = string().letters(strict: strict, message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input contains only digits.
  static String? Function(String) digits({
    bool strict = true,
    String message = 'Only digits are allowed.',
  }) {
    final schema = string().digits(strict: strict, message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input is alphanumeric.
  static String? Function(String) alphanumeric({
    bool strict = true,
    String message = 'Only letters and numbers are allowed.',
  }) {
    final schema = string().alphanumeric(strict: strict, message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input is in uppercase.
  static String? Function(String) uppercase({
    String message = 'Must be uppercase.',
  }) {
    final schema = string().upperCase(message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input is in lowercase.
  static String? Function(String) lowercase({
    String message = 'Must be lowercase.',
  }) {
    final schema = string().lowerCase(message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input starts with a given string.
  static String? Function(String) startsWith(String prefix, {String? message}) {
    final schema = string().startsWith(
      prefix,
      message: message ?? 'Must start with "$prefix".',
    );
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input ends with a given string.
  static String? Function(String) endsWith(String suffix, {String? message}) {
    final schema = string().endsWith(
      suffix,
      message: message ?? 'Must end with "$suffix".',
    );
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input contains a given string.
  static String? Function(String) contains(
    String substring, {
    String? message,
  }) {
    final schema = string().contains(
      substring,
      message: message ?? 'Must contain "$substring".',
    );
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input is a valid UUID.
  static String? Function(String) uuid({
    String message = 'Please enter a valid UUID.',
  }) {
    final schema = string().uuid(message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input is a valid hex color.
  static String? Function(String) hexColor({
    String message = 'Please enter a valid hex color.',
  }) {
    final schema = string().hexColor(message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input is a valid date-time string.
  static String? Function(String) dateTime({
    String message = 'Please enter a valid date-time.',
  }) {
    final schema = string().dateTime(message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input is a valid JWT.
  static String? Function(String) jwt({
    String message = 'Please enter a valid JWT.',
  }) {
    final schema = string().jwt(message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  /// Validates that the input is valid base64.
  static String? Function(String) base64({
    String message = 'Please enter valid base64.',
  }) {
    final schema = string().base64(message: message);
    return (value) {
      if (value.trim().isEmpty) return null;
      return _validate(schema, value);
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Number Validators (for string input that should be numeric)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Validates that the input is numeric.
  static String? Function(String) numeric({
    String message = 'Please enter a valid number.',
    bool allowNegative = true,
  }) {
    return (value) {
      if (value.trim().isEmpty) return null;
      final num = double.tryParse(value);
      if (num == null) return message;
      if (!allowNegative && num < 0) return 'Value cannot be negative.';
      return null;
    };
  }

  /// Validates that the input is an integer.
  static String? Function(String) integer({
    String message = 'Please enter a valid integer.',
    int? min,
    int? max,
  }) {
    return (value) {
      if (value.trim().isEmpty) return null;
      final num = int.tryParse(value);
      if (num == null) return message;
      if (min != null && num < min) return 'Value must be at least $min.';
      if (max != null && num > max) return 'Value must be at most $max.';
      return null;
    };
  }

  /// Validates that the input is a positive number.
  static String? Function(String) positive({
    String message = 'Value must be positive.',
  }) {
    return (value) {
      if (value.trim().isEmpty) return null;
      final num = double.tryParse(value);
      if (num == null) return 'Please enter a valid number.';
      if (num <= 0) return message;
      return null;
    };
  }

  /// Validates that the input is a negative number.
  static String? Function(String) negative({
    String message = 'Value must be negative.',
  }) {
    return (value) {
      if (value.trim().isEmpty) return null;
      final num = double.tryParse(value);
      if (num == null) return 'Please enter a valid number.';
      if (num >= 0) return message;
      return null;
    };
  }

  /// Validates that the input is between min and max.
  static String? Function(String) between(num min, num max, {String? message}) {
    return (value) {
      if (value.trim().isEmpty) return null;
      final num = double.tryParse(value);
      if (num == null) return 'Please enter a valid number.';
      if (num < min || num > max) {
        return message ?? 'Value must be between $min and $max.';
      }
      return null;
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Network Validators
  // ─────────────────────────────────────────────────────────────────────────────

  /// Validates that the input is a valid IP address.
  static String? Function(String) ip({
    String message = 'Please enter a valid IP address.',
    bool allowV6 = true,
  }) {
    return (value) {
      if (value.trim().isEmpty) return null;

      // IPv4 pattern
      final ipv4 = RegExp(
        r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
      );

      if (ipv4.hasMatch(value)) return null;

      if (allowV6) {
        // Simple IPv6 check
        final ipv6 = RegExp(r'^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$');
        if (ipv6.hasMatch(value)) return null;
      }

      return message;
    };
  }

  /// Validates that the input is a valid port number.
  static String? Function(String) port({
    String message = 'Please enter a valid port number (1-65535).',
  }) {
    return (value) {
      if (value.trim().isEmpty) return null;

      final port = int.tryParse(value);
      if (port == null || port < 1 || port > 65535) return message;
      return null;
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // List Validators
  // ─────────────────────────────────────────────────────────────────────────────

  /// Validates that the input is in a list of allowed values.
  static String? Function(String) inList(
    List<String> allowed, {
    String? message,
    bool caseSensitive = false,
  }) {
    return (value) {
      if (value.trim().isEmpty) return null;

      final check = caseSensitive ? value : value.toLowerCase();
      final allowedCheck = caseSensitive
          ? allowed
          : allowed.map((s) => s.toLowerCase()).toList();

      if (!allowedCheck.contains(check)) {
        return message ?? 'Value must be one of: ${allowed.join(', ')}';
      }
      return null;
    };
  }

  /// Validates that the input is NOT in a list of disallowed values.
  static String? Function(String) notIn(
    List<String> disallowed, {
    String? message,
    bool caseSensitive = false,
  }) {
    return (value) {
      if (value.trim().isEmpty) return null;

      final check = caseSensitive ? value : value.toLowerCase();
      final disallowedCheck = caseSensitive
          ? disallowed
          : disallowed.map((s) => s.toLowerCase()).toList();

      if (disallowedCheck.contains(check)) {
        return message ?? 'This value is not allowed.';
      }
      return null;
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Special Validators
  // ─────────────────────────────────────────────────────────────────────────────

  /// Validates that the input is a valid identifier (e.g., variable name).
  static String? Function(String) identifier({
    String message =
        'Must be a valid identifier (letters, numbers, underscores, starting with a letter).',
  }) {
    return (value) {
      if (value.trim().isEmpty) return null;
      if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(value)) {
        return message;
      }
      return null;
    };
  }

  /// Validates that the input matches a confirmation value.
  static String? Function(String) matches(
    String Function() getValue, {
    String message = 'Values do not match.',
  }) {
    return (value) {
      if (value != getValue()) return message;
      return null;
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Combinators
  // ─────────────────────────────────────────────────────────────────────────────

  /// Combines multiple validators.
  ///
  /// Runs validators in order and returns the first error, or null if all pass.
  static String? Function(String) combine(
    List<String? Function(String)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Makes a validator optional (only runs if value is not empty).
  static String? Function(String) optional(String? Function(String) validator) {
    return (value) {
      if (value.trim().isEmpty) return null;
      return validator(value);
    };
  }

  /// Creates a custom validator from an Acanthis schema.
  ///
  /// ```dart
  /// final validator = Validators.fromSchema(
  ///   string().email().min(5).max(100),
  /// );
  /// ```
  static String? Function(String) fromSchema(AcanthisString schema) {
    return (value) => _validate(schema, value);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helper Methods
  // ─────────────────────────────────────────────────────────────────────────────

  static String? _validate(AcanthisString schema, String value) {
    final result = schema.tryParse(value);
    if (result.success) return null;
    return result.errors.values.firstOrNull ?? 'Invalid value';
  }
}

/// Extension to create validators directly from Acanthis schemas.
extension AcanthisValidatorExtension on AcanthisString {
  /// Converts this Acanthis schema to a validator function.
  ///
  /// ```dart
  /// final validator = string().email().min(5).toValidator();
  /// final error = validator('test'); // Returns error message or null
  /// ```
  String? Function(String) toValidator({bool optional = false}) {
    return (value) {
      if (optional && value.trim().isEmpty) return null;
      final result = tryParse(value);
      if (result.success) return null;
      return result.errors.values.firstOrNull ?? 'Invalid value';
    };
  }
}
