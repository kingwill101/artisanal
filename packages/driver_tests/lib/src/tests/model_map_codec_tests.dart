import 'package:test/test.dart';

import '../models/models.dart';

void runModelMapCodecTests() {
  group('Model map helpers', () {
    test('user toMap uses column names', () {
      final author = Author(id: 1, name: 'Ada', active: true);

      final map = author.toMap();

      expect(map['id'], equals(1));
      expect(map['name'], equals('Ada'));
      expect(map['active'], anyOf(equals(true), equals(1)));
      expect(map.containsKey('created_at'), isFalse);
    });

    test('user fromMap uses column names', () {
      final author = AuthorOrmExtension.fromMap({
        'id': 2,
        'name': 'Bob',
        'active': false,
      });

      expect(author, isA<$Author>());
      expect(author.id, equals(2));
      expect(author.name, equals('Bob'));
    });

    test('tracked toMap/fromMap round-trips', () {
      final tracked = $Author.fromMap({
        'id': 3,
        'name': 'Cara',
        'active': true,
      });

      final map = tracked.toMap();
      expect(map['name'], equals('Cara'));

      expect(map, containsPair('name', 'Cara'));
    });

    test('companion helpers map tracked models', () {
      final tracked = Authors.fromMap({
        'id': 4,
        'name': 'Dana',
        'active': true,
      });

      expect(tracked, isA<$Author>());
      final map = Authors.toMap(tracked);
      expect(map['name'], equals('Dana'));
    });
  });
}
