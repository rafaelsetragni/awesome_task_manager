import 'dart:async';

import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';
import 'package:flutter_test/flutter_test.dart';

class TestCancelableTask<T> extends CancelableTask<T> {
  TestCancelableTask({
    required super.managerId,
    required super.taskId,
    required super.task,
    super.timeout,
  });

  @override
  void emitNewState() {
    // Do nothing to isolate tests from TaskManager
  }
}

void main() {
  group('CancelableTask', () {
    const managerId = 'test_manager';
    const taskId = 'test_task';

    test('execute completes with the correct value', () async {
      final task = TestCancelableTask<String>(
        managerId: managerId,
        taskId: taskId,
        task: (status) async => 'success',
      );

      final result = await task.execute();

      expect(result, 'success');
      expect(task.isCompleted, isTrue);
      expect(task.isExecuting, isFalse);
      expect(task.result, 'success');
    });

    test('cancel completes the future with a CancellationException', () async {
      final task = TestCancelableTask<String>(
        managerId: managerId,
        taskId: taskId,
        task: (status) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'should not complete';
        },
      );

      final future = task.execute();
      final wasCanceled = task.cancel();

      expect(wasCanceled, isTrue);
      expect(task.isCanceled, isTrue);
      expect(task.isCompleted, isTrue);
      await expectLater(future, throwsA(isA<CancellationException>()));
    });

    test('cancel does nothing if task is already completed', () async {
      final task = TestCancelableTask<String>(
        managerId: managerId,
        taskId: taskId,
        task: (status) async => 'done',
      );

      await task.execute();
      final wasCanceled = task.cancel();

      expect(wasCanceled, isFalse);
      expect(task.isCanceled, isFalse);
    });

    test('execute throws TimeoutException if task exceeds timeout', () async {
      final task = TestCancelableTask<String>(
        managerId: managerId,
        taskId: taskId,
        task: (status) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return 'should not complete';
        },
        timeout: const Duration(milliseconds: 50),
      );

      final future = task.execute();

      await expectLater(future, throwsA(isA<TimeoutException>()));
      expect(task.isTimedOut, isTrue);
      expect(task.isCompleted, isTrue);
    });

    test('execute catches and stores exceptions from the task', () async {
      final exception = Exception('task failed');
      final task = TestCancelableTask<String>(
        managerId: managerId,
        taskId: taskId,
        task: (status) async => throw exception,
      );

      final future = task.execute();

      await expectLater(future, throwsA(isA<Exception>()));
      expect(task.isError, isTrue);
      expect(task.lastException, isA<Exception>());
      expect(task.isCompleted, isTrue);
    });

    test('execute does not run the task more than once', () async {
      int executionCount = 0;
      final task = TestCancelableTask<String>(
        managerId: managerId,
        taskId: taskId,
        task: (status) async {
          executionCount++;
          return 'success';
        },
      );

      await task.execute();
      await task.execute();
      await task.execute();

      expect(executionCount, 1);
    });
  });
}
