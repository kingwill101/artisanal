# Launch day fixes (COMPLETED)

These are issues reported from a user launching a new project


## infer table name from class name if not provided [DONE]

## fresh project  no  artifacts would have existed prior. need to check the logic [DONE]

## consider auto creating a primary key when none is provided [DONE]

## schema.sql is suppose to be a file not a folder [DONE]

## Bump versions to 0.1.0-dev+1 [DONE]

## Auto-add dependencies in ormed_cli init [DONE]
4 │ class User extends Model<User> {
│       ^^^^
╵
➜  ormtest


Note from rails documentation 
```
Primary keys - By default, Active Record will use an integer column named id as the table's primary key (bigint for PostgreSQL, MySQL, and MariaDB, integer for SQLite). When using Active Record Migrations to create your tables, this column will be automatically created.
```


## generator bug? [DONE]


import "package:ormed/ormed.dart";
part 'user.orm.dart';

@OrmModel(table: "users")
class User extends Model<User> {
@OrmField(isPrimaryKey: true, autoIncrement: true)
final int id;
final String name;
final String address;

User(this.name, this.address, this.id);
}


offending block (constructor not being called with named arguments)


@override
$User decode(Map<String, Object?> data, ValueCodecRegistry registry) {
final int userIdValue =
registry.decodeField<int>(_$UserIdField, data['id']) ?? 0;
final String userNameValue =
registry.decodeField<String>(_$UserNameField, data['name']) ??
(throw StateError('Field name on User cannot be null.'));
final String userAddressValue =
registry.decodeField<String>(_$UserAddressField, data['address']) ??
(throw StateError('Field address on User cannot be null.'));
final model = $User(userNameValue, userAddressValue, userIdValue);
model._attachOrmRuntimeMetadata({
'id': userIdValue,
'name': userNameValue,
'address': userAddressValue,
});
return model;
}
}



error • lib/src/database/models/user.orm.dart:190:19 • The named parameter 'address' is required, but there's no corresponding argument.
Try adding the required argument. • missing_required_argument
error • lib/src/database/models/user.orm.dart:190:19 • The named parameter 'name' is required, but there's no corresponding argument. Try
adding the required argument. • missing_required_argument
error • lib/src/database/models/user.orm.dart:190:25 • Too many positional arguments: 0 expected, but 3 found. Try removing the extra
positional arguments, or specifying the name for named arguments. • extra_positional_arguments_could_be_named





## generated seeder.dart should auto import the generated registry file [DONE]


import 'package:{{package name}}/orm_registry.g.dart';

error • lib/src/database/seeders.dart:19:46 • The method 'registerGeneratedModels' isn't defined for the type 'ModelRegistry'. Try
correcting the name to the name of an existing method, or defining a method named 'registerGeneratedModels'. • undefined_method
error • lib/src/database/seeders.dart:26:35 • The method 'registerGeneratedModels' isn't defined for the type 'ModelRegistry'. Try
correcting the name to the name of an existing method, or defining a method named 'registerGeneratedModels'. • undefined_method
warning • lib/src/database/seeders.dart:4:8 • Unused import: 'seeders/database_seeder.dart'. Try removing the import directive. •
unused_import
info • lib/src/database/seeders.dart:1:8 • The imported package 'ormed_cli' isn't a dependency of the importing package. Try adding a
dependency for 'ormed_cli' in the 'pubspec.yaml' file. • depend_on_referenced_packages

