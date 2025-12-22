// Has One relationship example
import 'package:ormed/ormed.dart';

part 'has_one.orm.dart';

// #region relation-has-one
@OrmModel(table: 'users')
class UserWithProfile extends Model<UserWithProfile> {
  const UserWithProfile({required this.id, this.profile});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmRelation.hasOne(target: Profile, foreignKey: 'user_id')
  final Profile? profile;
}

@OrmModel(table: 'profiles')
class Profile extends Model<Profile> {
  const Profile({required this.id, required this.userId, required this.bio});

  @OrmField(isPrimaryKey: true)
  final int id;

  final int userId;
  final String bio;
}
// #endregion relation-has-one
