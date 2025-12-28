import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  test('json cast accepts raw strings for Object fields', () {
    const field = FieldDefinition(
      name: 'payload',
      columnName: 'payload',
      dartType: 'Object',
      resolvedType: 'Object?',
      isPrimaryKey: false,
      isNullable: true,
      codecType: 'json',
    );
    final registry = ValueCodecRegistry.instance;

    final decoded = registry.decodeField<Object?>(field, 'done');
    expect(decoded, 'done');

    final encoded = registry.encodeField(field, decoded);
    expect(encoded, jsonEncode('done'));
  });

  test('json cast accepts map input for Object fields', () {
    const field = FieldDefinition(
      name: 'payload',
      columnName: 'payload',
      dartType: 'Object',
      resolvedType: 'Object?',
      isPrimaryKey: false,
      isNullable: true,
      codecType: 'json',
    );
    final registry = ValueCodecRegistry.instance;

    final decoded = registry.decodeField<Object?>(field, <String, Object?>{
      'value': 1,
    });
    expect(decoded, equals(<String, Object?>{'value': 1}));

    final encoded = registry.encodeField(field, decoded);
    expect(encoded, jsonEncode(<String, Object?>{'value': 1}));
  });
}
