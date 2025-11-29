import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/resolvers/cancel_previous_resolver.dart';
import 'package:awesome_task_manager/src/types/types.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper function to simulate a task with a delay.
Future<String> delayedTask(String taskName,
    {Duration delay = const Duration(milliseconds: 100)}) async {
  await Future.delayed(delay);
  return 'completed: $taskName';
}

void main() {
  group('CancelPreviousResolver', () {
    const managerId = 'test_manager';
    const taskId = 'test_task';

    test('should execute tasks normally when limit is not reached', () async {
      final resolver = CancelPreviousResolver<String>(
        managerId: managerId,
        taskId: taskId,
        maximumParallelTasks: 2,
      );

      final future1 = resolver.executeTask(
        callerReference: 'test1',
        task: (status) => delayedTask('task1'),
      );

      final future2 = resolver.executeTask(
        callerReference: 'test2',
        task: (status) => delayedTask('task2'),
      );

      final results = await Future.wait([future1, future2]);

      expect(results[0].value, 'completed: task1');
      expect(results[1].value, 'completed: task2');
    });

    test('should cancel the oldest task when limit is reached', () async {
      final resolver = CancelPreviousResolver<String>(
        managerId: managerId,
        taskId: taskId,
        maximumParallelTasks: 1,
      );

      final future1 = resolver.executeTask(
        callerReference: 'test1',
        task: (status) =>
            delayedTask('task1', delay: const Duration(milliseconds: 200)),
      );

      // Add a small delay to ensure the first task starts executing
      await Future.delayed(const Duration(milliseconds: 10));

      final future2 = resolver.executeTask(
        callerReference: 'test2',
        task: (status) => delayedTask('task2'),
      );

      // The first future should contain a CancellationException
      expect((await future1).exception, isA<CancellationException>());

      // The second future should complete successfully
      final result2 = await future2;
      expect(result2.value, 'completed: task2');
    });

    test('should cancel the oldest task when limit of 2 is reached', () async {
      final resolver = CancelPreviousResolver<String>(
        managerId: managerId,
        taskId: taskId,
        maximumParallelTasks: 2,
      );

      final future1 = resolver.executeTask(
        callerReference: 'test1',
        task: (status) =>
            delayedTask('task1', delay: const Duration(milliseconds: 300)),
      );
      await Future.delayed(const Duration(milliseconds: 10));

      final future2 = resolver.executeTask(
        callerReference: 'test2',
        task: (status) =>
            delayedTask('task2', delay: const Duration(milliseconds: 300)),
      );
      await Future.delayed(const Duration(milliseconds: 10));

      final future3 = resolver.executeTask(
        callerReference: 'test3',
        task: (status) => delayedTask('task3'),
      );

      // The first future should contain a CancellationException
      final result1 = await future1;
      expect(result1.exception, isA<CancellationException>());

      // The second and third futures should complete successfully
      final results = await Future.wait([future2, future3]);
      expect(results[0].value, 'completed: task2');
      expect(results[1].value, 'completed: task3');
    });

    test('should handle rapid execution', () async {
      final resolver = CancelPreviousResolver<String>(
        managerId: managerId,
        taskId: taskId,
        maximumParallelTasks: 1,
      );

      final futures = <Future<TaskResult<String>>>[];

      for (var i = 0; i < 5; i++) {
        futures.add(resolver.executeTask(
          callerReference: 'test$i',
          task: (status) =>
              delayedTask('task$i', delay: const Duration(milliseconds: 150)),
        ));
        await Future.delayed(const Duration(milliseconds: 20));
      }

      final results = await Future.wait(futures);

      // First 4 tasks should be canceled
      for (var i = 0; i < 4; i++) {
        expect(results[i].exception, isA<CancellationException>());
      }

      // The last task should complete successfully
      expect(results[4].value, 'completed: task4');
      expect(results[4].exception, isNull);
    });
  });
}
