import 'query_grammar.dart';
import 'query_plan.dart';

/// Clause kinds that can be extended by drivers.
enum DriverExtensionKind { select, where, orderBy, groupBy, having, join }

/// Result of compiling a custom clause into SQL and bindings.
class DriverExtensionFragment {
  DriverExtensionFragment({required this.sql, List<Object?>? bindings})
    : bindings = List.unmodifiable(bindings ?? const []);

  final String sql;
  final List<Object?> bindings;
}

/// Context passed to driver extension handlers during compilation.
class DriverExtensionContext {
  const DriverExtensionContext({
    required this.grammar,
    required this.plan,
    required this.tableIdentifier,
    this.joinAlias,
  });

  /// Active grammar for the current driver.
  final QueryGrammar grammar;

  /// The plan being compiled.
  final QueryPlan plan;

  /// Identifier for the base table in the current query.
  final String tableIdentifier;

  /// Identifier for the joined table when compiling join constraints.
  final String? joinAlias;
}

/// Function signature used to compile a custom clause.
typedef DriverExtensionCompiler =
    DriverExtensionFragment Function(
      DriverExtensionContext context,
      Object? payload,
    );

/// Handler for a driver extension clause.
class DriverExtensionHandler {
  const DriverExtensionHandler({
    required this.kind,
    required this.key,
    required this.compile,
  });

  final DriverExtensionKind kind;
  final String key;
  final DriverExtensionCompiler compile;
}

/// Bundle of driver extension handlers.
abstract class DriverExtension {
  const DriverExtension();

  List<DriverExtensionHandler> get handlers;
}

/// Thrown when a driver extension key is registered twice for the same kind.
class DriverExtensionConflictError extends StateError {
  DriverExtensionConflictError({
    required this.driverName,
    required this.kind,
    required this.key,
  }) : super(
         'Driver extension "$key" already registered for '
         '${_describeKind(kind)} on "$driverName".',
       );

  final String driverName;
  final DriverExtensionKind kind;
  final String key;
}

/// Thrown when a driver extension handler is missing during compilation.
class MissingDriverExtensionError extends StateError {
  MissingDriverExtensionError({
    required this.driverName,
    required this.kind,
    required this.key,
  }) : super(
         'Missing driver extension "$key" for '
         '${_describeKind(kind)} on "$driverName".',
       );

  final String driverName;
  final DriverExtensionKind kind;
  final String key;
}

/// Registry of driver extension handlers by clause kind.
class DriverExtensionRegistry {
  DriverExtensionRegistry({
    required this.driverName,
    Iterable<DriverExtension>? extensions,
  }) : _handlers = {
         for (final kind in DriverExtensionKind.values)
           kind: <String, DriverExtensionHandler>{},
       } {
    if (extensions != null) {
      registerAll(extensions);
    }
  }

  final String driverName;
  final Map<DriverExtensionKind, Map<String, DriverExtensionHandler>> _handlers;

  /// Registers all handlers from the provided [extensions].
  void registerAll(Iterable<DriverExtension> extensions) {
    for (final extension in extensions) {
      registerExtension(extension);
    }
  }

  /// Registers the handlers from a single [extension].
  void registerExtension(DriverExtension extension) {
    for (final handler in extension.handlers) {
      registerHandler(handler);
    }
  }

  /// Registers a single [handler].
  void registerHandler(DriverExtensionHandler handler) {
    final key = handler.key.trim();
    if (key.isEmpty) {
      throw ArgumentError.value(
        handler.key,
        'key',
        'Extension keys cannot be empty.',
      );
    }
    final kindHandlers = _handlers[handler.kind]!;
    if (kindHandlers.containsKey(key)) {
      throw DriverExtensionConflictError(
        driverName: driverName,
        kind: handler.kind,
        key: key,
      );
    }
    kindHandlers[key] = handler;
  }

  /// Returns the handler for [kind] and [key], or null if not found.
  DriverExtensionHandler? handlerFor(DriverExtensionKind kind, String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return _handlers[kind]?[trimmed];
  }

  /// Resolves a handler or throws when missing.
  DriverExtensionHandler resolve(DriverExtensionKind kind, String key) {
    final handler = handlerFor(kind, key);
    if (handler == null) {
      throw MissingDriverExtensionError(
        driverName: driverName,
        kind: kind,
        key: key.trim(),
      );
    }
    return handler;
  }
}

String _describeKind(DriverExtensionKind kind) {
  switch (kind) {
    case DriverExtensionKind.select:
      return 'SELECT clauses';
    case DriverExtensionKind.where:
      return 'WHERE clauses';
    case DriverExtensionKind.orderBy:
      return 'ORDER BY clauses';
    case DriverExtensionKind.groupBy:
      return 'GROUP BY clauses';
    case DriverExtensionKind.having:
      return 'HAVING clauses';
    case DriverExtensionKind.join:
      return 'JOIN constraints';
  }
}

/// Implemented by drivers that can register custom query clause extensions.
abstract class DriverExtensionHost {
  DriverExtensionRegistry get driverExtensions;

  void registerExtensions(Iterable<DriverExtension> extensions) {
    driverExtensions.registerAll(extensions);
  }
}
