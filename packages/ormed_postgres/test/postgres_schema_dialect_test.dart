import 'package:ormed/migrations.dart';
import 'package:ormed_postgres/src/postgres_schema_dialect.dart';
import 'package:test/test.dart';

void main() {
  final compiler = SchemaPlanCompiler(const PostgresSchemaDialect());

  test('applies driver-specific column overrides', () {
    final builder = SchemaBuilder();
    builder.create('profiles', (table) {
      table.json('prefs')
        ..nullable()
        ..driverType('postgres', const ColumnType.jsonb());
      table
          .string('locale')
          .driverOverride('postgres', collation: '"und-x-icu"');
      table.timestamp('synced_at', timezoneAware: true)
        ..nullable()
        ..driverDefault('postgres', expression: 'timezone(\'UTC\', now())');
    });

    final sql = compiler.compile(builder.build()).statements.first.sql;
    expect(sql, contains('"prefs" JSONB'));
    expect(sql, contains('DEFAULT timezone(\'UTC\', now())'));
    expect(sql, contains('COLLATE "und-x-icu"'));
  });

  test('creates tables with indexes and constraints', () {
    final builder = SchemaBuilder();
    builder.create('users', (table) {
      table.increments('id');
      table.string('email').unique();
      table.boolean('admin').defaultValue(false);
      table.timestamps();
      table.primary(['id'], name: 'users_primary');
      table.index(['email', 'admin'], name: 'users_email_admin_index');
    });

    final preview = compiler.compile(builder.build());
    final sqlStatements = preview.statements.map((s) => s.sql).toList();
    expect(sqlStatements.length, greaterThanOrEqualTo(2));
    final createSql = sqlStatements.first;
    expect(createSql, contains('CREATE TABLE "users"'));
    expect(createSql, contains('PRIMARY KEY ("id")'));
    expect(createSql, contains('"email" VARCHAR(255) NOT NULL'));
    expect(createSql, contains('"admin" BOOLEAN NOT NULL DEFAULT false'));
    expect(
      sqlStatements,
      contains(
        'CREATE INDEX "users_email_admin_index" '
        'ON "users" ("email", "admin")',
      ),
    );
  });

  test('alters tables and supports renames', () {
    final builder = SchemaBuilder();
    builder.table('users', (table) {
      table.string('nickname');
      table.renameColumn('email', 'primary_email');
      table.dropColumn('admin');
      table.index(['primary_email'], name: 'users_primary_email_index');
      table.dropIndex('users_email_admin_index');
    });
    builder.rename('users', 'accounts');

    final preview = compiler.compile(builder.build());
    final sql = preview.statements.map((s) => s.sql).toList();
    expect(
      sql,
      contains(
        'ALTER TABLE "users" ADD COLUMN "nickname" VARCHAR(255) NOT NULL',
      ),
    );
    expect(sql, contains('ALTER TABLE "users" DROP COLUMN "admin"'));
    expect(
      sql,
      contains('ALTER TABLE "users" RENAME COLUMN "email" TO "primary_email"'),
    );
    expect(
      sql,
      contains(
        'CREATE INDEX "users_primary_email_index" ON "users" ("primary_email")',
      ),
    );
    expect(sql, contains('DROP INDEX IF EXISTS "users_email_admin_index"'));
    expect(sql.last, equals('ALTER TABLE "users" RENAME TO "accounts"'));
  });

  test('drops tables with cascade and emits raw SQL', () {
    final builder = SchemaBuilder();
    builder.drop('widgets', ifExists: true, cascade: true);
    builder.raw('VACUUM');

    final statements = compiler.compile(builder.build()).statements;
    expect(statements.first.sql, 'DROP TABLE IF EXISTS "widgets" CASCADE');
    expect(statements.last.sql, 'VACUUM');
  });

  test('handles composite foreign keys with reference actions', () {
    final builder = SchemaBuilder();
    builder.create('members', (table) {
      table.integer('team_id');
      table.integer('user_id');
      table.primary(['team_id', 'user_id'], name: 'members_pkey');
      table.foreign(
        ['team_id'],
        references: 'teams',
        referencedColumns: ['id'],
        onDelete: ReferenceAction.restrict,
        onUpdate: ReferenceAction.cascade,
      );
    });

    final statements = compiler.compile(builder.build()).statements;
    final createSql = statements.first.sql;
    expect(createSql, contains('PRIMARY KEY ("team_id", "user_id")'));
    expect(createSql, contains('REFERENCES "teams" ("id")'));
    expect(createSql, contains('ON DELETE RESTRICT ON UPDATE CASCADE'));
  });

  test('schema plan compiler emits SQL for composite indexes and renames', () {
    final builder = SchemaBuilder();
    builder.create('teams', (table) {
      table.integer('org_id');
      table.integer('id');
      table.string('name');
      table.primary(['org_id', 'id'], name: 'teams_primary');
      table.unique(['name'], name: 'teams_name_unique');
    });
    builder.create('members', (table) {
      table.integer('org_id');
      table.integer('team_id');
      table.integer('user_id');
      table.string('role').defaultValue('member');
      table.primary(['org_id', 'team_id', 'user_id'], name: 'members_primary');
      table.index(['org_id', 'team_id'], name: 'members_org_team_index');
      table.foreign(
        ['org_id', 'team_id'],
        references: 'teams',
        referencedColumns: ['org_id', 'id'],
        onDelete: ReferenceAction.cascade,
        onUpdate: ReferenceAction.restrict,
      );
    });
    builder.table('members', (table) {
      table.renameColumn('role', 'member_role');
      table.index([
        'member_role',
        'org_id',
        'team_id',
      ], name: 'members_role_org_team_index');
      table.dropIndex('members_org_team_index');
    });
    builder.rename('members', 'group_members');
    builder.drop('group_members', ifExists: true, cascade: true);

    final preview = compiler.compile(builder.build());
    final sql = preview.statements.map((s) => s.sql).join('\n');

    expect(
      sql,
      contains(
        'FOREIGN KEY ("org_id", "team_id") REFERENCES "teams" ("org_id", "id") ON DELETE CASCADE ON UPDATE RESTRICT',
      ),
    );
    expect(
      sql,
      contains(
        'CREATE INDEX "members_org_team_index" ON "members" ("org_id", "team_id")',
      ),
    );
    expect(
      sql,
      contains(
        'CREATE INDEX "members_role_org_team_index" ON "members" ("member_role", "org_id", "team_id")',
      ),
    );
    expect(
      sql,
      contains('ALTER TABLE "members" RENAME COLUMN "role" TO "member_role"'),
    );
    expect(sql, contains('ALTER TABLE "members" RENAME TO "group_members"'));
    expect(sql, contains('DROP TABLE IF EXISTS "group_members" CASCADE'));
  });

  test('new fluent helpers compile into postgres SQL', () {
    final builder = SchemaBuilder();
    builder.create('devices', (table) {
      table.ulid('device_ulid');
      table.char('code', length: 8);
      table.tinyText('notes');
      table.geometry('location');
      table.geography('region');
      table.vector('embedding', dimensions: 3);
      table.point('position');
      table.multiPolygon('regions');
      table.geometryCollection('shapes');
      table.computed('code_slug', 'lower(code)', stored: true);
      table.year('model_year');
      table.ipAddress();
      table.macAddress();
      table.unsignedBigInteger('owner_id');
      table
          .foreign(['owner_id'], references: 'users', referencedColumns: ['id'])
          .onDelete(ReferenceAction.cascade);
      table.rememberToken();
      table.timestamps(nullable: true);
      table.nullableTimestamps();
      table.datetimes();
      table.softDeletes();
      table.fullText(['notes'], name: 'devices_notes_fulltext');
      table.spatialIndex(['location'], name: 'devices_location_spatial');
      table.rawIndex('lower(code)', name: 'devices_code_lower_index');
    });

    final preview = compiler.compile(builder.build());
    final statements = preview.statements;
    final sql = statements.first.sql;
    final indexSql = statements.map((s) => s.sql).join('\n');
    expect(sql, contains('"device_ulid" VARCHAR(26)'));
    expect(sql, contains('"code" VARCHAR(8)'));
    expect(sql, contains('"location" GEOMETRY'));
    expect(sql, contains('"region" GEOGRAPHY'));
    expect(sql, contains('"embedding" VECTOR(3)'));
    expect(sql, contains('"position" POINT'));
    expect(sql, contains('"regions" MULTIPOLYGON'));
    expect(sql, contains('"shapes" GEOMETRYCOLLECTION'));
    expect(sql, contains('GENERATED ALWAYS AS (lower(code)) STORED'));
    expect(sql, contains('"owner_id" BIGINT'));
    expect(sql, contains('"remember_token" VARCHAR(100)'));
    expect(sql, contains('"deleted_at" TIMESTAMP WITHOUT TIME ZONE'));
    expect(
      sql,
      contains(
        'FOREIGN KEY ("owner_id") REFERENCES "users" ("id") ON DELETE CASCADE',
      ),
    );
    expect(
      indexSql,
      contains('CREATE INDEX "devices_notes_fulltext" ON "devices" USING GIN'),
    );
    expect(
      indexSql,
      contains(
        "to_tsvector('simple'::regconfig, COALESCE(\"notes\"::text, ''))",
      ),
    );
    expect(
      indexSql,
      contains(
        'CREATE INDEX "devices_location_spatial" ON "devices" USING GIST',
      ),
    );
    expect(indexSql, contains('lower(code)'));
  });
}
