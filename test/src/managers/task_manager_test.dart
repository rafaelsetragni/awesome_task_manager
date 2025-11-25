import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/resolvers/task_resolver.dart';
import 'package:awesome_task_manager/src/types/types.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integrations/manager_integration_test.dart';

class FakeTaskResolver<T> extends Fake implements TaskResolver<T> {}

void main() {
  final managerId = 'manager 1';

  group('TaskManager - exceptions', () {
    test('TaskManager - invalid parameters', () async {
      final taskManager =
          AwesomeTaskManager().createSharedResultManager(managerId: managerId);
      expect(
          () => taskManager.executeTaskSharingResult<String>(
              callerReference: 'TaskManager Test',
              taskId: 'task1',
              task: (status) async => ''),
          returnsNormally);

      expect(
          () => taskManager.executeTaskSharingResult<String>(
              callerReference: 'TaskManager Test',
              taskId: 'task1',
              task: (status) async => 'test'),
          returnsNormally);

      expect(
          () => taskManager.executeTaskSharingResult<int>(
              callerReference: 'TaskManager Test',
              taskId: 'task1',
              task: (status) async => 1),
          throwsA(isA<MismatchTasksReturnsException>()));
    });
  });

  group('TaskManager - resolvers', () {
    test('TaskManager - executeTask in resultSharing mode', () async {
      final taskManager =
          AwesomeTaskManager().createSharedResultManager(managerId: managerId);

      late Future<TaskResult<int>> future;
      expect(
        () => future = taskManager.executeTaskSharingResult(
            callerReference: 'resultSharing test',
            taskId: '1',
            task: (status) async => 1),
        returnsNormally,
      );
      final TaskResult<int> taskResult = await future;
      expect(taskResult.result, 1);
    });

    test('TaskManager - executeTask in sequentialQueue mode', () async {
      final taskManager = AwesomeTaskManager()
          .createSequentialQueueManager(managerId: managerId);

      late Future<TaskResult<int>> future;
      expect(
        () => future = taskManager.executeSequentialTask(
            callerReference: 'resultSharing test',
            taskId: '1',
            task: (status) async => 1,
            maximumParallelTasks: 1),
        returnsNormally,
      );
      final TaskResult<int> taskResult = await future;
      expect(taskResult.result, 1);
    });

    test('TaskManager - executeTask in TaskPool mode', () async {
      const poolSize = 3;
      final taskManager = AwesomeTaskManager()
          .createTaskPoolManager(managerId: managerId, poolSize: poolSize);

      List<Future<TaskResult<int>>> futures = [];
      for (int count = 0; count < poolSize; count++) {
        expect(
          () => futures.add(taskManager.executeTaskInPool(
            callerReference: 'resultSharing test',
            taskId: '1',
            task: (status) =>
                Future.delayed(taskDuration).then((value) => count),
          )),
          returnsNormally,
        );
      }

      late Future<TaskResult<int>> extraFuture;
      expect(
        () => extraFuture = taskManager.executeTaskInPool(
          callerReference: 'resultSharing test',
          taskId: '1',
          task: (status) =>
              Future.delayed(taskDuration * 2).then((value) => poolSize + 1),
        ),
        returnsNormally,
      );

      final currentTaskQueue =
          taskManager.taskResolvers.entries.first.value.taskQueue;

      int countingTasksInExecution() {
        final identified = currentTaskQueue.map((c) => c.isExecuting ? 1 : 0);
        if (identified.isEmpty) return 0;
        return identified.reduce((a, b) => a + b);
      }

      expect(currentTaskQueue.length, poolSize + 1);
      expect(countingTasksInExecution(), poolSize);

      final List<TaskResult<int>> taskResults = await Future.wait(futures);
      expect(countingTasksInExecution(), 1);

      for (int count = 0; count < poolSize; count++) {
        expect(taskResults[count].result, count);
        expect(taskResults[count].exception, isNull);
      }

      TaskResult<int> lastResult = await extraFuture;
      expect(lastResult.result, poolSize + 1);
      expect(lastResult.exception, isNull);
      expect(countingTasksInExecution(), 0);
    });

    test('TaskManager - executeTask in rejectAfterThreshold mode', () async {
      final taskManager =
          AwesomeTaskManager().createRejectedAfterThresholdManager(
        managerId: managerId,
      );

      late Future<TaskResult<int>> future;
      expect(
        () => future = taskManager.executeRejectingAfterThreshold(
            callerReference: 'resultSharing test',
            taskId: '1',
            task: (status) async => 1),
        returnsNormally,
      );
      final TaskResult<int> taskResult = await future;
      expect(taskResult.result, 1);
    });

    test('TaskManager - executeCancellingPreviousTask', () async {
      final taskManager = CancelPreviousTaskManager(
        managerId: 'test',
        maximumParallelTasks: 1,
      );

      final future1 = taskManager.executeCancellingPreviousTask(
        callerReference: 'test1',
        taskId: 'task',
        task: (status) =>
            Future.delayed(const Duration(milliseconds: 200), () => 'first'),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final future2 = taskManager.executeCancellingPreviousTask(
        callerReference: 'test2',
        taskId: 'task',
        task: (status) =>
            Future.delayed(const Duration(milliseconds: 50), () => 'second'),
      );

      final result1 = await future1;
      expect(result1.exception, isA<CancellationException>());

      final result2 = await future2;
      expect(result2.result, 'second');
    });
  });

  group('resetManager', () {
    test('reset should clear all internal list controls', () {
      final taskManager = AwesomeTaskManager().createSharedResultManager(
        managerId: managerId,
      );
      final result = taskManager.executeTaskSharingResult<String>(
          callerReference: 'resetManager',
          taskId: 'task1',
          task: (status) =>
              Future.delayed(const Duration(seconds: 1)).then((value) => ''));

      expect(taskManager.resolverTypes.isNotEmpty, isTrue);
      expect(taskManager.taskResolvers.isNotEmpty, isTrue);

      taskManager.resetManager();

      expect(taskManager.resolverTypes.isEmpty, isTrue);
      expect(taskManager.taskResolvers.isEmpty, isTrue);
    });
  });

  group('TaskManager - getTaskStatusStream', () {
    test('should return the same stream event for the same taskId', () async {
      final taskManager = AwesomeTaskManager().createSharedResultManager(
        managerId: managerId,
      );
      const taskId = 'my_task';

      final events1 = <TaskStatus?>[];
      final events2 = <TaskStatus?>[];

      final stream1 = AwesomeTaskManager().getTaskStatusStream(taskId: taskId);
      final stream2 = AwesomeTaskManager().getTaskStatusStream(taskId: taskId);

      final sub1 = stream1.listen(events1.add);
      final sub2 = stream2.listen(events2.add);

      expect(identical(stream1, stream2), isFalse);

      await taskManager.executeTaskSharingResult(
        callerReference: 'TaskManager Test',
        taskId: taskId,
        task: (status) async {
          return 1;
        },
      );

      await Future.delayed(Duration.zero);

      await sub1.cancel();
      await sub2.cancel();

      expect(events1, equals(events2),
          reason: 'Both streams must emit exactly the same events');

      taskManager.resetManager();
    });
  });
}
