import 'package:awesome_task_manager/src/tasks/task_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskResult', () {
    group('Factory Constructor', () {
      test('should create a Success result when result is provided', () {
        final result = TaskResult<String>(result: 'success');
        expect(result, isA<TaskSuccess<String>>());
        expect(result.value, 'success');
      });

      test('should create a Failure result when exception is provided', () {
        final exception = Exception('error');
        final result = TaskResult<String>(exception: exception);
        expect(result, isA<TaskFailure<String>>());
        expect(result.exception, exception);
      });
    });

    group('Success', () {
      const success = TaskSuccess('data');

      test('getters return correct values', () {
        expect(success.isSuccess, isTrue);
        expect(success.isFailure, isFalse);
        expect(success.value, 'data');
        expect(success.exception, isNull);
      });

      test('fold calls onSuccess', () {
        final value = success.fold(
          onSuccess: (r) => 'Success: $r',
          onFailure: (e) => 'Failure: $e',
        );
        expect(value, 'Success: data');
      });

      test('map transforms the result', () {
        final mapped = success.map((r) => r.toUpperCase());
        expect(mapped, isA<TaskSuccess<String>>());
        expect(mapped.value, 'DATA');
      });

      test('mapError does nothing', () {
        final mapped = success.mapError((e) => Exception('New Error'));
        expect(mapped, same(success));
      });

      test('flatMap chains the operation', () {
        final flatMapped = success.flatMap((r) => TaskSuccess(r.length));
        expect(flatMapped, isA<TaskSuccess<int>>());
        expect(flatMapped.value, 4);
      });

      test('equality and hashCode work correctly', () {
        const anotherSuccess = TaskSuccess('data');
        const differentSuccess = TaskSuccess('other');
        expect(success, anotherSuccess);
        expect(success.hashCode, anotherSuccess.hashCode);
        expect(success == differentSuccess, isFalse);
      });

      test('toString returns correct representation', () {
        expect(success.toString(), 'Success(result: data)');
      });
    });

    group('Failure', () {
      final exception = Exception('error');
      final failure = TaskFailure<String>(exception);

      test('getters return correct values', () {
        expect(failure.isSuccess, isFalse);
        expect(failure.isFailure, isTrue);
        expect(failure.value, isNull);
        expect(failure.exception, exception);
      });

      test('fold calls onFailure', () {
        final value = failure.fold(
          onSuccess: (r) => 'Success: $r',
          onFailure: (e) => 'Failure: ${e.toString()}',
        );
        expect(value, 'Failure: ${exception.toString()}');
      });

      test('map returns a new Failure', () {
        final mapped = failure.map((r) => r.toUpperCase());
        expect(mapped, isA<TaskFailure<String>>());
        expect(mapped.exception, exception);
      });

      test('mapError transforms the exception', () {
        final newException = Exception('New Error');
        final mapped = failure.mapError((e) => newException);
        expect(mapped, isA<TaskFailure<String>>());
        expect(mapped.exception, newException);
      });

      test('flatMap returns a new Failure', () {
        final flatMapped = failure.flatMap((r) => TaskSuccess(r.length));
        expect(flatMapped, isA<TaskFailure<int>>());
        expect(flatMapped.exception, exception);
      });

      test('equality and hashCode work correctly', () {
        final anotherFailure = TaskFailure<String>(exception);
        final differentFailure = TaskFailure<String>(Exception('other'));
        expect(failure, anotherFailure);
        expect(failure.hashCode, anotherFailure.hashCode);
        expect(failure == differentFailure, isFalse);
      });

      test('toString returns correct representation', () {
        expect(failure.toString(), 'Failure(exception: $exception)');
      });
    });
  });
}
