import 'package:ormed/src/builder/emitters/model_subclass_emitter.dart';
import 'package:test/test.dart';

void main() {
  test('castValueForType casts non-nullable Object fields', () {
    expect(castValueForType('value', 'Object'), 'value as Object');
  });

  test('castValueForType leaves Object? and dynamic as-is', () {
    expect(castValueForType('value', 'Object?'), 'value');
    expect(castValueForType('value', 'dynamic'), 'value');
  });

  test('castValueForType casts other types', () {
    expect(castValueForType('value', 'String'), 'value as String');
  });
}
