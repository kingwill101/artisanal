import 'package:ormed/migrations.dart';

class CreateMixedConstructorsTable extends Migration {
  const CreateMixedConstructorsTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('mixed_constructors', (table) {
      table.id();
      table.string('name');
      table.string('description').nullable();
      table.timestamps();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('mixed_constructors');
  }
}
