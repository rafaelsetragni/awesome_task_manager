import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/resolvers/sequential_queue_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

const taskDuration = Duration(milliseconds: 250);

class FutureTracker {
  final String id;
  final DateTime createdAt;
  late final DateTime finishedAt;
  final Duration delayDuration;

  FutureTracker({required this.id, this.delayDuration = taskDuration})
      : createdAt = DateTime.now();

  @override
  String toString() =>
      '(id: $id, createdAt: ${createdAt.millisecondsSinceEpoch})';

  Future<FutureTracker> delay() async {
    print('$id created at $createdAt');
    await Future.delayed(delayDuration);
    finishedAt = DateTime.now();
    print('$id finished at $finishedAt');
    return this;
  }
}

void main() {
  group('SequentialQueueResolver - concurrency tests in FIFO', () {
    test('1 concurrent execution', () async {
      final resolver = SequentialQueueResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 1', maximumParallelTasks: 1);

      final startedAt = DateTime.now();
      final future1 = resolver.executeTask(
        callerReference: '1 concurrent execution',
        task: (status) async => FutureTracker(id: 'Task 1').delay(),
      );

      final results = await Future.wait([future1]);

      final future1FinishedAt = results[0].value?.createdAt;
      expect(future1FinishedAt, isNotNull);

      expect(future1FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[0].value?.id} was not executed when requested');
    });

    test('2 concurrent executions', () async {
      final resolver = SequentialQueueResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 2', maximumParallelTasks: 1);

      final startedAt = DateTime.now();
      final future1 = resolver.executeTask(
        callerReference: '2 concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 1').delay(),
      );

      final future2 = resolver.executeTask(
        callerReference: '2 concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 2').delay(),
      );

      final results = await Future.wait([future1, future2]);

      final future1FinishedAt = results[0].value?.createdAt;
      final future2FinishedAt = results[1].value?.createdAt;
      expect(future1FinishedAt, isNotNull);
      expect(future2FinishedAt, isNotNull);

      expect(future1FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[0].value?.id} was not executed when requested');

      expect(future2FinishedAt!.difference(startedAt),
          greaterThanOrEqualTo(taskDuration),
          reason:
              'The ${results[1].value?.id} did not wait for previous tasks');
    });

    test('3 concurrent executions', () async {
      final resolver = SequentialQueueResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 3', maximumParallelTasks: 1);

      final startedAt = DateTime.now();
      final Future<TaskResult> future1 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) async => FutureTracker(id: 'Future 1').delay(),
      );

      final Future<TaskResult> future2 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) async => FutureTracker(id: 'Future 2').delay(),
      );

      final Future<TaskResult> future3 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) async => FutureTracker(id: 'Future 3').delay(),
      );

      final results = await Future.wait([future1, future2, future3]);

      final future1FinishedAt = results[0].value?.createdAt;
      final future2FinishedAt = results[1].value?.createdAt;
      final future3FinishedAt = results[2].value?.createdAt;
      expect(future1FinishedAt, isNotNull);
      expect(future2FinishedAt, isNotNull);
      expect(future3FinishedAt, isNotNull);

      expect(future1FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[0].value?.id} was not executed when requested');

      expect(future2FinishedAt!.difference(startedAt),
          greaterThanOrEqualTo(taskDuration),
          reason:
              'The ${results[1].value?.id} did not wait for previous tasks');

      expect(future3FinishedAt!.difference(startedAt),
          greaterThanOrEqualTo(taskDuration * 2),
          reason:
              'The ${results[2].value?.id} did not wait for previous tasks');
    });
  });

  group('SequentialQueueResolver - concurrency tests in parallel', () {
    test('1 parallel concurrent execution', () async {
      final resolver = SequentialQueueResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 1', maximumParallelTasks: 2);

      final startedAt = DateTime.now();
      final future1 = resolver.executeTask(
        callerReference: '1 parallel concurrent execution',
        task: (status) async => FutureTracker(id: 'Task 1').delay(),
      );

      final results = await Future.wait([future1]);

      final future1FinishedAt = results[0].value?.createdAt;
      expect(future1FinishedAt, isNotNull);

      expect(future1FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[0].value?.id} was not executed when requested');
    });

    test('2 parallel concurrent executions', () async {
      final resolver = SequentialQueueResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 2', maximumParallelTasks: 2);

      final startedAt = DateTime.now();
      final future1 = resolver.executeTask(
        callerReference: '2 parallel concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 1').delay(),
      );

      final future2 = resolver.executeTask(
        callerReference: '2 parallel concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 2').delay(),
      );

      final results = await Future.wait([future1, future2]);

      final future1FinishedAt = results[0].value?.createdAt;
      final future2FinishedAt = results[1].value?.createdAt;
      expect(future1FinishedAt, isNotNull);
      expect(future2FinishedAt, isNotNull);

      expect(future1FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[0].value?.id} was not executed when requested');

      expect(future2FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[1].value?.id} was not executed when requested');
    });

    test('3 parallel concurrent executions', () async {
      final resolver = SequentialQueueResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 3', maximumParallelTasks: 2);

      final startedAt = DateTime.now();
      final Future<TaskResult> future1 = resolver.executeTask(
        callerReference: '3 parallel concurrent executions',
        task: (status) async => FutureTracker(id: 'Future 1').delay(),
      );

      final Future<TaskResult> future2 = resolver.executeTask(
        callerReference: '3 parallel concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 2').delay(),
      );

      final Future<TaskResult> future3 = resolver.executeTask(
        callerReference: '3 parallel concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 3').delay(),
      );

      final results = await Future.wait([future1, future2, future3]);

      final future1FinishedAt = results[0].value?.createdAt;
      final future2FinishedAt = results[1].value?.createdAt;
      final future3FinishedAt = results[2].value?.createdAt;
      expect(future1FinishedAt, isNotNull);
      expect(future2FinishedAt, isNotNull);
      expect(future3FinishedAt, isNotNull);

      expect(future1FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[0].value?.id} was not executed when requested');

      expect(future2FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[1].value?.id} was not executed when requested');

      expect(future3FinishedAt!.difference(startedAt),
          greaterThanOrEqualTo(taskDuration),
          reason:
              'The ${results[2].value?.id} did not wait for previous tasks');
    });

    test('4 parallel concurrent executions', () async {
      final resolver = SequentialQueueResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 3', maximumParallelTasks: 2);

      final startedAt = DateTime.now();
      final Future<TaskResult> future1 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions',
        task: (status) async => FutureTracker(id: 'Future 1').delay(),
      );

      final Future<TaskResult> future2 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 2').delay(),
      );

      final Future<TaskResult> future3 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 3').delay(),
      );

      final Future<TaskResult> future4 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 4').delay(),
      );

      final results = await Future.wait([future1, future2, future3, future4]);

      final future1FinishedAt = results[0].value?.createdAt;
      final future2FinishedAt = results[1].value?.createdAt;
      final future3FinishedAt = results[2].value?.createdAt;
      final future4FinishedAt = results[3].value?.createdAt;
      expect(future1FinishedAt, isNotNull);
      expect(future2FinishedAt, isNotNull);
      expect(future3FinishedAt, isNotNull);
      expect(future4FinishedAt, isNotNull);

      expect(future1FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[0].value?.id} was not executed when requested');

      expect(future2FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[1].value?.id} was not executed when requested');

      expect(future3FinishedAt!.difference(startedAt),
          greaterThanOrEqualTo(taskDuration),
          reason:
              'The ${results[2].value?.id} did not wait for previous tasks');

      expect(future3FinishedAt!.difference(startedAt),
          greaterThanOrEqualTo(taskDuration),
          reason:
              'The ${results[3].value?.id} did not wait for previous tasks');

      expect(
          future3FinishedAt!.difference(startedAt), lessThan(taskDuration * 2),
          reason:
              'The ${results[3].value?.id} did not wait for previous tasks');
    });

    test('4 parallel concurrent executions with long task', () async {
      final resolver = SequentialQueueResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 3', maximumParallelTasks: 2);

      final startedAt = DateTime.now();
      final Future<TaskResult<FutureTracker>> future1 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions with long task',
        task: (status) => FutureTracker(
          id: 'Future 1 long task',
          // A long task to occupy the slot execution during the test
          delayDuration: taskDuration * 3,
        ).delay(),
      );

      final Future<TaskResult<FutureTracker>> future2 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions with long task',
        task: (status) => FutureTracker(id: 'Future 2').delay(),
      );

      final Future<TaskResult<FutureTracker>> future3 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions with long task',
        task: (status) => FutureTracker(id: 'Future 3').delay(),
      );

      final Future<TaskResult<FutureTracker>> future4 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions with long task',
        task: (status) => FutureTracker(id: 'Future 4').delay(),
      );

      final results = await Future.wait([future1, future2, future3, future4]);

      final result1 = results[0].value;
      final result2 = results[1].value;
      final result3 = results[2].value;
      final result4 = results[3].value;
      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result3, isNotNull);
      expect(result4, isNotNull);

      expect(result1!.createdAt.difference(startedAt), lessThan(taskDuration),
          reason: 'The ${result1.id} was not executed when requested');

      expect(result2!.createdAt.difference(startedAt), lessThan(taskDuration),
          reason: 'The ${result2.id} was not executed when requested');

      expect(result3!.createdAt.millisecondsSinceEpoch,
          greaterThanOrEqualTo(result2.finishedAt.millisecondsSinceEpoch),
          reason: 'The ${result3.id} was not executed when requested');

      expect(result4!.createdAt.millisecondsSinceEpoch,
          greaterThanOrEqualTo(result3.finishedAt.millisecondsSinceEpoch),
          reason: 'The ${result4.id} was not executed when requested');
    });

    test('4 parallel concurrent executions with free slots', () async {
      final resolver = SequentialQueueResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 3', maximumParallelTasks: 4);

      final startedAt = DateTime.now();
      final Future<TaskResult<FutureTracker>> future1 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions with long task',
        task: (status) => FutureTracker(
          id: 'Future 1',
          // A long task to occupy the slot execution during the test
          delayDuration: taskDuration * 3,
        ).delay(),
      );

      final Future<TaskResult<FutureTracker>> future2 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions with free slots',
        task: (status) => FutureTracker(id: 'Task 2').delay(),
      );

      final Future<TaskResult<FutureTracker>> future3 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions with free slots',
        task: (status) => FutureTracker(id: 'Task 3').delay(),
      );

      final Future<TaskResult<FutureTracker>> future4 = resolver.executeTask(
        callerReference: '4 parallel concurrent executions with free slots',
        task: (status) => FutureTracker(id: 'Task 4').delay(),
      );

      final results = await Future.wait([future1, future2, future3, future4]);

      final result1 = results[0].value;
      final result2 = results[1].value;
      final result3 = results[2].value;
      final result4 = results[3].value;
      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result3, isNotNull);
      expect(result4, isNotNull);

      expect(result1!.createdAt.difference(startedAt), lessThan(taskDuration),
          reason: 'The ${result1.id} was not executed when requested');

      expect(result2!.createdAt.difference(startedAt), lessThan(taskDuration),
          reason: 'The ${result2.id} was not executed when requested');

      expect(result3!.createdAt.difference(startedAt), lessThan(taskDuration),
          reason: 'The ${result3.id} was not executed when requested');

      expect(result4!.createdAt.difference(startedAt), lessThan(taskDuration),
          reason: 'The ${result4.id} was not executed when requested');
    });
  });
}
