import 'package:ormed/migrations.dart';

class CreateAccessorUsersTable extends Migration {
  const CreateAccessorUsersTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('accessor_users', (table) {
      table.integer('id').primaryKey();
      table.string('first_name');
      table.string('last_name');
      table.string('email');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('accessor_users', ifExists: true);
  }
}
