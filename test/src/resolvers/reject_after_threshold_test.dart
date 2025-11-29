import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/resolvers/reject_after_threshold_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

const taskDuration = Duration(milliseconds: 250);

class FutureTracker {
  final String id;
  final DateTime createdAt;
  final Duration delayDuration;

  FutureTracker({required this.id, this.delayDuration = taskDuration})
      : createdAt = DateTime.now();

  @override
  String toString() =>
      '(id: $id, createdAt: ${createdAt.millisecondsSinceEpoch})';

  Future<FutureTracker> delay() async {
    await Future.delayed(delayDuration);
    return this;
  }
}

void main() {
  group('RejectAfterThresholdResolver - concurrency tests in FIFO', () {
    test('1 concurrent execution', () async {
      final resolver = RejectAfterThresholdResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 1', taskThreshold: 1);

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
      final resolver = RejectAfterThresholdResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 2', taskThreshold: 1);

      final startedAt = DateTime.now();
      final Future<TaskResult<FutureTracker>> future1 = resolver.executeTask(
        callerReference: '2 concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 1').delay(),
      );

      final Future<TaskResult<FutureTracker>> future2 = resolver.executeTask(
        callerReference: '2 concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 2').delay(),
      );

      final results = await Future.wait([future1, future2]);

      expect(results[0].value, isNotNull);
      expect(results[0].exception, isNull);

      expect(results[1].value, isNull);
      expect(results[1].exception, isNotNull);
      expect(results[1].exception, isA<TooManyTasksException>());

      final future1FinishedAt = results[0].value?.createdAt;
      expect(future1FinishedAt, isNotNull);

      expect(future1FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[0].value!.id} was not executed when requested');
    });

    test('3 concurrent executions', () async {
      final resolver = RejectAfterThresholdResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 2', taskThreshold: 2);

      final startedAt = DateTime.now();
      final Future<TaskResult<FutureTracker>> future1 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 1').delay(),
      );

      final Future<TaskResult<FutureTracker>> future2 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 2').delay(),
      );

      final Future<TaskResult<FutureTracker>> future3 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 2').delay(),
      );

      final results = await Future.wait([future1, future2, future3]);

      expect(results[0].value, isNotNull);
      expect(results[0].exception, isNull);

      expect(results[1].value, isNotNull);
      expect(results[1].exception, isNull);

      expect(results[2].value, isNull);
      expect(results[2].exception, isNotNull);
      expect(results[2].exception, isA<TooManyTasksException>());

      final future1FinishedAt = results[0].value?.createdAt;
      final future2FinishedAt = results[0].value?.createdAt;
      expect(future1FinishedAt, isNotNull);
      expect(future2FinishedAt, isNotNull);

      expect(future1FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[0].value!.id} was not executed when requested');

      expect(future2FinishedAt!.difference(startedAt), lessThan(taskDuration),
          reason:
              'The ${results[1].value!.id} was not executed when requested');
    });

    test('3 not concurrent executions', () async {
      final resolver = RejectAfterThresholdResolver<FutureTracker>(
          managerId: 'test', taskId: 'test 3', taskThreshold: 2);

      final startedAt = DateTime.now();
      final Future<TaskResult<FutureTracker>> future1 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) async => FutureTracker(id: 'Future 1').delay(),
      );

      final Future<TaskResult<FutureTracker>> future2 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) async => FutureTracker(id: 'Task 2').delay(),
      );

      final results = await Future.wait([future1, future2]);

      late final Future<TaskResult<FutureTracker>> future3;
      expect(
        () {
          future3 = resolver.executeTask(
            callerReference: '3 concurrent executions',
            task: (status) async => FutureTracker(id: 'Task 3').delay(),
          );
        },
        returnsNormally,
      );

      results.add(await future3);

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
              'The ${results[2].value?.id} was not executed when requested');
    });
  });
}
