import 'dart:math';

import 'package:awesome_task_manager/src/exceptions/task_exceptions.dart';
import 'package:awesome_task_manager/src/managers/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/types/types.dart';
import 'package:flutter_test/flutter_test.dart';

const testNameRandom = 'Random Tasks';
const numberOfTasks = 500;
const taskIdVariations = 30;
const taskDuration = Duration(milliseconds: 250);
const halfTaskDuration = Duration(milliseconds: 125);
const integrationTestTimeout = Timeout(Duration(minutes: 5));

typedef FutureInstanceTests<T> = ({
  String id,
  int testNumber,
  Future<TaskResult<T>> futureInstance
});

void main() {
  group('Integration tests', () {
    test('Integration tests - SharedResult $numberOfTasks random tasks',
        () async {
      final taskManager = AwesomeTaskManager().createSharedResultManager(
        managerId: 'test',
      );
      Future<int> task({required String taskId, required int result}) async {
        AwesomeTaskManager().log('Executing task $result...', name: taskId);
        await Future.delayed(taskDuration);
        return result;
      }

      final random = Random();

      // Run multiple concurrent tasks at once
      final List<FutureInstanceTests<int>> futures = [];
      for (int count = 0; count < numberOfTasks; count++) {
        final taskId = 'task ${1 + random.nextInt(taskIdVariations)}';
        futures.add((
          id: taskId,
          testNumber: count,
          futureInstance: taskManager.executeTaskSharingResult(
            callerReference: '$taskId ($count)',
            taskId: taskId,
            task: (status) => task(taskId: taskId, result: count),
          )
        ));
      }

      final Map<String, int> futureInstanceChecker = {};
      for (FutureInstanceTests<int> test in futures) {
        final currentValue = (await test.futureInstance).result;
        expect(currentValue, isNotNull);
        futureInstanceChecker[test.id] ??= currentValue!;
        final oldValue = futureInstanceChecker[test.id];

        expect(currentValue, oldValue,
            reason:
                'The task "${test.id}" received a different future than expected');
      }
    }, timeout: integrationTestTimeout);

    test('Integration tests - TaskPool $numberOfTasks random tasks', () async {
      const int poolSize = 5;
      final taskManager = AwesomeTaskManager()
          .createTaskPoolManager(managerId: 'test', poolSize: poolSize);

      Future<(DateTime, DateTime)> task({required String taskId}) async {
        final started = DateTime.now();
        AwesomeTaskManager().log('Executing task $taskId...', name: taskId);
        await Future.delayed(taskDuration);
        final ended = DateTime.now();
        return (started, ended);
      }

      final random = Random();

      // Run multiple concurrent tasks at once
      final List<FutureInstanceTests<(DateTime, DateTime)>> futures = [];
      for (int count = 0; count < numberOfTasks; count++) {
        final taskId = 'task ${1 + random.nextInt(taskIdVariations)}';
        futures.add((
          id: taskId,
          testNumber: count,
          futureInstance: taskManager.executeTaskInPool(
            callerReference: '$taskId ($count)',
            taskId: taskId,
            task: (status) => task(taskId: taskId),
          ),
        ));
      }

      final Map<String, List<(bool, DateTime)>> startTimes = {};
      for (FutureInstanceTests<(DateTime, DateTime)> test in futures) {
        final result = await test.futureInstance;
        expect(result, isNotNull);

        final DateTime startedAt = result.result!.$1;
        final DateTime finishedAt = result.result!.$2;

        startTimes[test.id] ??= [];
        startTimes[test.id]!.add((true, startedAt));
        startTimes[test.id]!.add((false, finishedAt));
      }

      for (MapEntry<String, List<(bool, DateTime)>> entry
          in startTimes.entries) {
        final timeEvents = entry.value;
        // Sort time events based on the time
        timeEvents.sort((a, b) => a.$2.compareTo(b.$2));

        int currentParallel = 0;

        // Iterate through the events
        for (var event in timeEvents) {
          if (event.$1) {
            currentParallel++; // Start of a task
          } else {
            currentParallel--; // End of a task
          }

          expect(currentParallel, lessThanOrEqualTo(poolSize),
              reason:
                  'More than $poolSize tasks ran simultaneously for ${entry.key}');
        }
      }
    }, timeout: integrationTestTimeout);

    test('Integration tests - SequentialQueue $numberOfTasks random tasks',
        () async {
      final taskManager = AwesomeTaskManager().createSequentialQueueManager(
        managerId: 'test',
      );
      Future<DateTime> task({required String taskId}) async {
        final startedAt = DateTime.now();
        AwesomeTaskManager().log('Executing task $taskId...', name: taskId);
        await Future.delayed(taskDuration);
        return startedAt;
      }

      final random = Random();

      // Run multiple concurrent tasks at once
      final List<FutureInstanceTests<DateTime>> futures = [];
      for (int count = 0; count < numberOfTasks; count++) {
        final taskId = 'task ${1 + random.nextInt(taskIdVariations)}';
        futures.add((
          id: taskId,
          testNumber: count,
          futureInstance: taskManager.executeSequentialTask(
              callerReference: '$taskId ($count)',
              taskId: taskId,
              task: (status) => task(taskId: taskId),
              maximumParallelTasks: 1)
        ));
      }

      final Map<String, List<DateTime>> futureInstanceChecker = {};
      for (FutureInstanceTests<DateTime> test in futures) {
        final currentStartedAt = (await test.futureInstance).result;
        expect(currentStartedAt, isNotNull);
        futureInstanceChecker[test.id] ??= [];
        futureInstanceChecker[test.id]!.add(currentStartedAt!);
      }

      for (MapEntry<String, List<DateTime>> createdAtEntry
          in futureInstanceChecker.entries) {
        // Sort the DateTime objects for each task type
        createdAtEntry.value.sort((a, b) => a.compareTo(b));

        // Iterate through the sorted list and compare consecutive elements
        for (int i = 1; i < createdAtEntry.value.length; i++) {
          final DateTime previousCreatedAt = createdAtEntry.value[i - 1];
          final DateTime currentCreatedAt = createdAtEntry.value[i];

          expect(currentCreatedAt.difference(previousCreatedAt),
              greaterThanOrEqualTo(taskDuration),
              reason:
                  'The task "${createdAtEntry.key}" executed in parallel when was not allowed');
        }
      }
    }, timeout: integrationTestTimeout);

    test(
        'Integration tests - RejectedAfterThreshold $numberOfTasks random tasks',
        () async {
      final startedAt = DateTime.now();
      final random = Random();
      const int taskThreshold = 3;

      final taskManager = AwesomeTaskManager()
          .createRejectedAfterThresholdManager(
              managerId: 'test', taskThreshold: taskThreshold);

      Future<DateTime> task({required String taskId}) async {
        final startedAt = DateTime.now();
        AwesomeTaskManager().log('Executing task $taskId...', name: taskId);
        await Future.delayed(taskDuration);
        return startedAt;
      }

      // Run multiple concurrent tasks at once
      final List<FutureInstanceTests<DateTime>> futures = [];
      for (int count = 0; count < numberOfTasks; count++) {
        final taskId = 'task ${1 + random.nextInt(taskIdVariations)}';
        futures.add((
          id: taskId,
          testNumber: count,
          futureInstance: taskManager.executeRejectingAfterThreshold(
            callerReference: '$taskId ($count)',
            taskId: taskId,
            task: (status) => task(taskId: taskId),
          )
        ));
      }

      final Map<String, List<TaskResult<DateTime>>> executions = {};
      for (FutureInstanceTests<DateTime> test in futures) {
        (executions[test.id] ??= []).add(await test.futureInstance);
      }

      for (MapEntry<String, List<TaskResult<DateTime>>> entry
          in executions.entries) {
        int successfullyTasks = 0;
        for (TaskResult<DateTime> task in entry.value) {
          if (task.result != null) {
            successfullyTasks++;
            expect(
              task.result!.difference(startedAt),
              lessThan(taskDuration),
              reason: 'The allowed task did not executed when expected',
            );
          } else {
            expect(task.exception, isA<TooManyTasksException>(),
                reason:
                    'Subsequent tasks should be rejected with TooManyTasksException.');
          }
        }
        expect(successfullyTasks, taskThreshold,
            reason: 'Not all allowed tasks was executed successfully.');
      }
    }, timeout: integrationTestTimeout);
  });

  int countMaxSimultaneousTasks(
      List<DateTime> startedTimes, Duration duration) {
    startedTimes.sort((a, b) => a.compareTo(b)); // Ensure times are sorted

    int maxSimultaneous = 0;
    for (int i = 0; i < startedTimes.length; i++) {
      int simultaneousTasks = 1; // Start count with the current task
      DateTime startTime = startedTimes[i];
      DateTime endTime = startTime.add(duration);

      // Count how many tasks are still running
      for (int j = 1; j < i; j++) {
        final currentStartTime = startedTimes[j];
        if (endTime.isAfter(currentStartTime)) break;
        simultaneousTasks++;
      }

      if (simultaneousTasks > maxSimultaneous) {
        maxSimultaneous = simultaneousTasks;
      }
    }

    return maxSimultaneous;
  }
}
