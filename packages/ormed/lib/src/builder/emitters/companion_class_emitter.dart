import '../helpers.dart';
import '../model_context.dart';

class CompanionClassEmitter {
  CompanionClassEmitter(this.context);

  final ModelContext context;

  String emit() {
    final buffer = StringBuffer();
    final className = context.className;
    final generatedClassName = context.trackedModelClassName;
    final companionName = pluralize(className);

    buffer.writeln('class $companionName {');
    buffer.writeln('  const $companionName._();');
    buffer.writeln();

    buffer.writeln('  /// Starts building a query for [$generatedClassName].');
    buffer.writeln('  ///');
    buffer.writeln('  /// {@macro ormed.query}');
    buffer.writeln(
      '  static Query<$generatedClassName> query([String? connection]) =>',
    );
    buffer.writeln(
      '      Model.query<$generatedClassName>(connection: connection);',
    );
    buffer.writeln();

    buffer.writeln(
      '  static Future<$generatedClassName?> find(Object id, {String? connection}) =>',
    );
    buffer.writeln(
      '      Model.find<$generatedClassName>(id, connection: connection);',
    );
    buffer.writeln();

    buffer.writeln(
      '  static Future<$generatedClassName> findOrFail(Object id, {String? connection}) =>',
    );
    buffer.writeln(
      '      Model.findOrFail<$generatedClassName>(id, connection: connection);',
    );
    buffer.writeln();

    buffer.writeln(
      '  static Future<List<$generatedClassName>> all({String? connection}) =>',
    );
    buffer.writeln(
      '      Model.all<$generatedClassName>(connection: connection);',
    );
    buffer.writeln();

    buffer.writeln('  static Future<int> count({String? connection}) =>');
    buffer.writeln(
      '      Model.count<$generatedClassName>(connection: connection);',
    );
    buffer.writeln();

    buffer.writeln('  static Future<bool> anyExist({String? connection}) =>');
    buffer.writeln(
      '      Model.anyExist<$generatedClassName>(connection: connection);',
    );
    buffer.writeln();

    buffer.writeln('  static Query<$generatedClassName> where(');
    buffer.writeln('    String column,');
    buffer.writeln('    String operator,');
    buffer.writeln('    dynamic value, {');
    buffer.writeln('    String? connection,');
    buffer.writeln(
      '  }) => Model.where<$generatedClassName>(column, operator, value, connection: connection);',
    );
    buffer.writeln();

    buffer.writeln('  static Query<$generatedClassName> whereIn(');
    buffer.writeln('    String column,');
    buffer.writeln('    List<dynamic> values, {');
    buffer.writeln('    String? connection,');
    buffer.writeln(
      '  }) => Model.whereIn<$generatedClassName>(column, values, connection: connection);',
    );
    buffer.writeln();

    buffer.writeln('  static Query<$generatedClassName> orderBy(');
    buffer.writeln('    String column, {');
    buffer.writeln('    String direction = "asc",');
    buffer.writeln('    String? connection,');
    buffer.writeln(
      '  }) => Model.orderBy<$generatedClassName>(column, direction: direction, connection: connection);',
    );
    buffer.writeln();

    buffer.writeln(
      '  static Query<$generatedClassName> limit(int count, {String? connection}) =>',
    );
    buffer.writeln(
      '      Model.limit<$generatedClassName>(count, connection: connection);',
    );
    buffer.writeln();

    buffer.writeln('  /// Creates a [Repository] for [$generatedClassName].');
    buffer.writeln('  ///');
    buffer.writeln('  /// {@macro ormed.repository}');
    buffer.writeln(
      '  static Repository<$generatedClassName> repo([String? connection]) =>',
    );
    buffer.writeln(
      '      Model.repository<$generatedClassName>(connection: connection);',
    );
    buffer.writeln();

    buffer.writeln(
      '  /// Builds a tracked model from a column/value map.',
    );
    buffer.writeln(
      '  static $generatedClassName fromMap(Map<String, Object?> data, {ValueCodecRegistry? registry}) =>',
    );
    buffer.writeln(
      '      _${generatedClassName}Definition.fromMap(data, registry: registry);',
    );
    buffer.writeln();

    buffer.writeln(
      '  /// Converts a tracked model to a column/value map.',
    );
    buffer.writeln(
      '  static Map<String, Object?> toMap($generatedClassName model, {ValueCodecRegistry? registry}) =>',
    );
    buffer.writeln(
      '      _${generatedClassName}Definition.toMap(model, registry: registry);',
    );
    buffer.writeln();

    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }
}
