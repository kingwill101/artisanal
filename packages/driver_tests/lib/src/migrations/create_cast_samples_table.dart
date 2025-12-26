import 'package:ormed/migrations.dart';

class CreateCastSamplesTable extends Migration {
  const CreateCastSamplesTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('cast_samples', (table) {
      table.integer('id').primaryKey();
      table.string('name');
      table.boolean('is_active');
      table.integer('visits');
      table.double('ratio');
      table.date('started_on');
      table.dateTime('updated_at');
      table.decimal('amount', precision: 10, scale: 2);
      table.string('status');
      table.string('secret');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('cast_samples', ifExists: true);
  }
}
