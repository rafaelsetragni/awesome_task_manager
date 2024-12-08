import 'package:awesome_task_manager/src/exceptions/task_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';

void main() {
  group('CancelableTask Tests', () {
    test('Task executes successfully', () async {
      var task = CancelableTask<String>(
        taskId: 'test',
        task: (status) async => 'result',
      );

      expect(await task.execute(), 'result');
      expect(task.isCompleted, isTrue);
      expect(task.isCanceled, isFalse);
      expect(task.isTimedOut, isFalse);
      expect(task.isError, isFalse);
    });

    test('Task is marking executing correctly', () async {
      var task = CancelableTask<String>(
        taskId: 'test',
        task: (status) => Future
          .delayed(const Duration(milliseconds: 250))
          .then((value) => 'result'),
      );


      late Future<String> future;
      expect(task.isExecuting, isFalse);
      expect(() => future = task.execute(), returnsNormally);
      expect(task.isExecuting, isTrue);

      expect(task.isCanceled, isFalse);
      expect(task.isCompleted, isFalse);
      expect(task.isTimedOut, isFalse);
      expect(task.isError, isFalse);

      try {
        expect(await future, 'result');
      } catch (e){
        fail(e.toString());
      }

      expect(task.isCompleted, isTrue);
      expect(task.isExecuting, isFalse);
    });

    test('Task is cancelled correctly', () async {
      var task = CancelableTask<String>(
        taskId: 'test',
        task: (status) async {
          await Future.delayed(const Duration(seconds: 1));
          return 'result';
        },
      );

      final future = task.execute();
      expect(task.cancel(), isTrue);
      expect(task.isCanceled, isTrue);
      expect(task.isCompleted, isTrue);
      expect(task.isTimedOut, isFalse);
      expect(task.isError, isFalse);

      await expectLater(future, throwsA(isA<CancellationException>()));
    });

    test('Task times out correctly', () async {
      var task = CancelableTask<String>(
        taskId: 'test',
        task: (status) async {
          await Future.delayed(const Duration(seconds: 1));
          return 'result';
        },
        timeout: const Duration(milliseconds: 500),
      );

      await expectLater(task.execute(), throwsA(isA<TimeoutException>()));
      expect(task.isTimedOut, isTrue);
      expect(task.isCompleted, isTrue);
      expect(task.isCanceled, isFalse);
      expect(task.isError, isFalse);
    });

    test('Task handles error correctly', () async {
      var task = CancelableTask<String>(
        taskId: 'test',
        task: (status) async {
          throw Exception('Test error');
        },
      );

      await expectLater(task.execute(), throwsException);
      expect(task.isError, isTrue);
      expect(task.isCompleted, isTrue);
      expect(task.isCanceled, isFalse);
      expect(task.isTimedOut, isFalse);
    });
  });
}
