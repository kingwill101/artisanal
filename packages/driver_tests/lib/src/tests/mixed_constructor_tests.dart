import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import '../models/models.dart';

void runMixedConstructorTests() {
  ormedGroup('MixedConstructorModel', (ds) {
    test('can insert and retrieve model with mixed constructor', () async {
      final repo = ds.context.repository<MixedConstructorModel>();
      
      final model = MixedConstructorModel(
        0, // id (auto-increment)
        'Test Name',
        description: 'Test Description',
      );
      
      final saved = await repo.insert(model);
      
      expect(saved.id, isNot(0));
      expect(saved.name, 'Test Name');
      expect(saved.description, 'Test Description');
      
      final retrieved = await ds
          .query<MixedConstructorModel>()
          .whereEquals('id', saved.id)
          .first();
          
      expect(retrieved, isNotNull);
      expect(retrieved!.id, saved.id);
      expect(retrieved.name, 'Test Name');
      expect(retrieved.description, 'Test Description');
    });

    test('can update model with mixed constructor', () async {
      final repo = ds.context.repository<MixedConstructorModel>();
      
      final model = await repo.insert(MixedConstructorModel(
        0,
        'Original Name',
      ));
      
      // Use the tracked model to update
      final tracked = model.toTracked();
      tracked.name = 'Updated Name';
      tracked.description = 'New Description';
      await repo.update(tracked);
      
      final refreshed = await model.refresh();
      expect(refreshed.name, 'Updated Name');
      expect(refreshed.description, 'New Description');
    });

    test('InsertDto inserts and returns model', () async {
      final repo = ds.context.repository<MixedConstructorModel>();

      final dto = MixedConstructorModelInsertDto(
        name: 'DTO Insert',
        description: 'Inserted via DTO',
      );

      final saved = await repo.insert(dto);

      expect(saved.id, isNotNull);
      expect(saved.name, 'DTO Insert');
      expect(saved.description, 'Inserted via DTO');

      final fetched = await ds
          .query<MixedConstructorModel>()
          .whereEquals('id', saved.id)
          .first();
      expect(fetched, isNotNull);
      expect(fetched!.name, 'DTO Insert');
      expect(fetched.description, 'Inserted via DTO');
    });

    test('InsertDto supports optional fields omitted', () async {
      final repo = ds.context.repository<MixedConstructorModel>();

      final dto = MixedConstructorModelInsertDto(
        name: 'Only Name',
      );

      final saved = await repo.insert(dto);
      expect(saved.id, isNotNull);
      expect(saved.name, 'Only Name');
      expect(saved.description, isNull);
    });

    test('UpdateDto updates existing record (PK in data)', () async {
      final repo = ds.context.repository<MixedConstructorModel>();

      final created = await repo.insert(MixedConstructorModelInsertDto(
        name: 'Before Update',
        description: 'Old',
      ));

      final updated = await repo.update(MixedConstructorModelUpdateDto(
        id: created.id,
        name: 'After Update',
        description: 'New',
      ));

      expect(updated.name, 'After Update');
      expect(updated.description, 'New');

      final fetched = await ds
          .query<MixedConstructorModel>()
          .whereEquals('id', created.id)
          .first();
      expect(fetched, isNotNull);
      expect(fetched!.name, 'After Update');
      expect(fetched.description, 'New');
    });

    test('UpdateDto with Partial.copyWith where updates by PK', () async {
      final repo = ds.context.repository<MixedConstructorModel>();

      final created = await repo.insert(MixedConstructorModelInsertDto(
        name: 'Original',
      ));

      final baseWhere = const MixedConstructorModelPartial();
      final updated = await repo.update(
        MixedConstructorModelUpdateDto(
          name: 'Renamed',
          description: 'Set via Partial where',
        ),
        where: baseWhere.copyWith(id: created.id),
      );

      expect(updated.name, 'Renamed');
      expect(updated.description, 'Set via Partial where');

      final fetched = await ds
          .query<MixedConstructorModel>()
          .whereEquals('id', created.id)
          .first();
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Renamed');
      expect(fetched.description, 'Set via Partial where');
    });

    test('InsertDto.copyWith composes values immutably', () async {
      final repo = ds.context.repository<MixedConstructorModel>();

      final base = const MixedConstructorModelInsertDto();
      final dto = base.copyWith(name: 'Via copyWith', description: 'Desc');
      final saved = await repo.insert(dto);

      expect(saved.name, 'Via copyWith');
      expect(saved.description, 'Desc');
    });

    test('UpdateDto.copyWith composes values immutably', () async {
      final repo = ds.context.repository<MixedConstructorModel>();

      final created = await repo.insert(
        const MixedConstructorModelInsertDto(name: 'Before', description: 'X'),
      );

      final base = const MixedConstructorModelUpdateDto(id: null);
      final dto = base.copyWith(id: created.id, name: 'After');
      final updated = await repo.update(dto);

      expect(updated.id, created.id);
      expect(updated.name, 'After');
      expect(updated.description, 'X');
    });
  });
}
