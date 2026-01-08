import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  test('OrmException uses message as string output', () {
    final error = OrmException('hello');
    expect(error.toString(), 'hello');
  });

  test('DriverException includes driver and operation in output', () {
    final error = DriverException(
      driver: 'sqlite',
      operation: 'alter_table_add_primary_key',
      message: 'nope',
      hint: 'use schema.create',
    );
    expect(
      error.toString(),
      'DriverException(sqlite/alter_table_add_primary_key): nope',
    );
    expect(error.hint, 'use schema.create');
  });
}
