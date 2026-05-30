import 'package:flutter_test/flutter_test.dart';
import 'package:persis_app/core/network/api_result.dart';

void main() {
  group('ApiResult', () {
    test('ApiResult.success creates correct object', () {
      final result = ApiResult.success('Testing Data');

      expect(result.isSuccess, isTrue);
      expect(result.data, 'Testing Data');
      expect(result.message, isNull);
    });

    test('ApiResult.failure creates correct object', () {
      final result = ApiResult<String>.failure('An error occurred');

      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
      expect(result.message, 'An error occurred');
    });
  });
}
