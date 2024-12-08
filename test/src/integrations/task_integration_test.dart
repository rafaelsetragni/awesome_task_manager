import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';
import 'package:awesome_task_manager/src/exceptions/task_exceptions.dart';
import 'package:awesome_task_manager/src/status/task_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('TaskStatus Tests', () {
    test('isCancelled returns false when respective task is not cancelled', () async {
      var cancelableTask = CancelableTask<String>(
          taskId: 'status',
          task: (status) =>
              Future
                  .delayed(const Duration(milliseconds: 250))
                  .then((value) => '')
      );
      var taskStatus = TaskStatus(cancelableTask);

      expect(taskStatus.isCanceled, isFalse);
      expect(() => cancelableTask.execute(), returnsNormally);
      expect(taskStatus.isCanceled, isFalse);

      await cancelableTask.future;
      expect(() => cancelableTask.future, returnsNormally);
    });

    test('isCancelled returns true when respective task is cancelled before execution', () async {
      var cancelableTask1 = CancelableTask<String>(
          taskId: 'status',
          task: (status) =>
              Future
                  .delayed(const Duration(milliseconds: 250))
                  .then((value) => '')
      );
      var taskStatus = TaskStatus(cancelableTask1);

      expect(taskStatus.isCanceled, isFalse);
      expect(cancelableTask1.cancel(), isTrue);
      expect(taskStatus.isCanceled, isTrue);

      await expectLater(
          cancelableTask1.future,
          throwsA(isA<CancellationException>())
      );
    });

    test('isCancelled returns true when respective task is cancelled during execution', () async {
      var cancelableTask1 = CancelableTask<String>(
          taskId: 'status',
          task: (status) =>
              Future
                  .delayed(const Duration(milliseconds: 250))
                  .then((value) => '')
      );
      var taskStatus = TaskStatus(cancelableTask1);

      expect(taskStatus.isCanceled, isFalse);

      final executeFuture = cancelableTask1.execute();
      expect(cancelableTask1.cancel(), isTrue);
      expect(taskStatus.isCanceled, isTrue);

      await executeFuture.catchError((e){
        print(e);
        return '';
      });

      await expectLater(
              () async => await executeFuture,
          throwsA(isA<CancellationException>())
      );
    });

    test('isCancelled returns true when respective task is cancelled after execution', () async {
      var cancelableTask1 = CancelableTask<String>(
          taskId: 'status',
          task: (status) =>
              Future
                  .delayed(const Duration(milliseconds: 250))
                  .then((value) => '')
      );
      var taskStatus = TaskStatus(cancelableTask1);

      expect(taskStatus.isCanceled, isFalse);

      final executeFuture = cancelableTask1.execute();
      await executeFuture.catchError((e){
        print(e);
        return '';
      });

      await expectLater(() async => await executeFuture, returnsNormally);
      expect(cancelableTask1.cancel(), isFalse);
      expect(taskStatus.isCanceled, isFalse);
    });

    test('isCompleted returns true only after task is completed', () async {
      var cancelableTask = CancelableTask<String>(
          taskId: 'status',
          task: (status) =>
              Future.delayed(const Duration(milliseconds: 250), () => '')
      );
      var taskStatus = TaskStatus(cancelableTask);

      // Start an async operation
      expect(taskStatus.isCompleted, isFalse);

      final cancelableFuture = cancelableTask.execute();

      // The task is not yet complete immediately after starting it
      expect(taskStatus.isCompleted, isFalse);

      // Wait for the task to complete
      await cancelableFuture;

      // Now the task should be complete
      expect(taskStatus.isCompleted, isTrue);
    });

    test('isTimedOut returns true when task times out', () async {
      var cancelableTask = CancelableTask<String>(
          taskId: 'status',
          task: (status) async {
            await Future.delayed(const Duration(seconds: 1));
            return '';
          },
          timeout: const Duration(milliseconds: 1)
      );
      var taskStatus = TaskStatus(cancelableTask);

      bool didSucceed = false;
      try {
        await cancelableTask.execute();
        didSucceed = true;
      } catch (e) {
        expect(e, isA<TimeoutException>());
      }

      expect(taskStatus.isTimedOut, isTrue);
      expect(
          didSucceed,
          isFalse,
          reason: 'Expected execute method to throw an exception, but'
              ' it did not.');

    });

    test('isOnError returns true when task encounters an error', () async {
      var cancelableTask = CancelableTask<String>(
          taskId: 'status',
          task: (status) async {
            await Future.delayed(const Duration(milliseconds: 10));
            throw Exception('test isOnError');
          },
      );
      var taskStatus = TaskStatus(cancelableTask);

      bool didSucceed = false;
      try {
        await cancelableTask.execute();
        didSucceed = true;
      } catch (e) {
        expect(e, isA<Exception>());
      }

      expect(taskStatus.isError, isTrue);
      expect(
          didSucceed,
          isFalse,
          reason: 'Expected execute method to throw an exception, but'
              ' it did not.');

    });
  });
}
