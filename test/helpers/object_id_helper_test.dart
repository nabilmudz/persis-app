import 'package:flutter_test/flutter_test.dart';
import 'package:persis_app/helpers/object_id_helper.dart';

void main() {
  group('ObjectIdHelper', () {
    test('generateLocalId returns string with prefix local_', () {
      final id = ObjectIdHelper.generateLocalId();
      expect(id.startsWith('local_'), isTrue);
    });

    test('generateLocalId returns unique ids', () {
      final id1 = ObjectIdHelper.generateLocalId();
      final id2 = ObjectIdHelper.generateLocalId();
      expect(id1, isNot(equals(id2)));
    });

    test('generateMongoObjectId returns 24 character string', () {
      final id = ObjectIdHelper.generateMongoObjectId();
      expect(id.length, 24);
    });

    test('generateMongoObjectId returns only hex characters', () {
      final id = ObjectIdHelper.generateMongoObjectId();
      final hexRegExp = RegExp(r'^[0-9a-fA-F]+$');
      expect(hexRegExp.hasMatch(id), isTrue);
    });

    test('generateMongoObjectId returns unique ids', () {
      final id1 = ObjectIdHelper.generateMongoObjectId();
      final id2 = ObjectIdHelper.generateMongoObjectId();
      expect(id1, isNot(equals(id2)));
    });
  });
}
