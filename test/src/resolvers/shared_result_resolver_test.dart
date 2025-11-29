import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/resolvers/shared_result_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integrations/manager_integration_test.dart';

class FutureTracker {
  final String id;
  final String expectedOutput;
  final DateTime createdAt;
  final Future<TaskResult> futureInstance;

  FutureTracker(
      {required this.id,
      required this.expectedOutput,
      required this.createdAt,
      required this.futureInstance});

  @override
  String toString() =>
      '(id: $id, createdAt: ${createdAt.millisecondsSinceEpoch})';
}

Future<String> simpleTaskCalculator({
  required String taskId,
  required String number,
  Duration fakeDelay = const Duration(milliseconds: 250),
}) async {
  await Future.delayed(fakeDelay);
  return '$taskId: ${(int.tryParse(number) ?? 0) + 1}';
}

void main() {
  group('SharedResultResolver - concurrency tests', () {
    test('1 concurrent execution', () async {
      final resolver = SharedResultResolver(managerId: 'test', taskId: '1');

      final future = await resolver.executeTask(
          callerReference: '1 concurrent execution',
          task: (status) => simpleTaskCalculator(taskId: '1', number: '1'));

      expect(future.value, '1: 2',
          reason: 'The result of simpleTask is different than expected');
    });

    test('2 concurrent executions', () async {
      final resolver = SharedResultResolver(managerId: 'test', taskId: '1');

      final result1 = resolver.executeTask(
        callerReference: '2 concurrent executions',
        task: (status) => simpleTaskCalculator(taskId: '1', number: '1'),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final result2 = resolver.executeTask(
        callerReference: '2 concurrent executions',
        task: (status) => simpleTaskCalculator(taskId: '1', number: '2'),
      );

      final results = await Future.wait([result1, result2]);

      expect(results.first.hashCode, results.last.hashCode,
          reason: 'The execution of request 1 was not shared with request 2');

      expect(results.first.value, '1: 2',
          reason: 'The result of simpleTask is different than expected');

      expect(results.last.value, '1: 2',
          reason: 'The result of simpleTask is different than expected');
    });

    test('3 concurrent executions', () async {
      final resolver = SharedResultResolver(managerId: 'test', taskId: '1');

      final result1 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) => simpleTaskCalculator(taskId: '1', number: '1'),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final result2 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) => simpleTaskCalculator(taskId: '1', number: '2'),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final result3 = resolver.executeTask(
        callerReference: '3 concurrent executions',
        task: (status) => simpleTaskCalculator(taskId: '1', number: '3'),
      );

      final results = await Future.wait([result1, result2, result3]);

      expect(results[0].value, '1: 2',
          reason: 'The result of simpleTask is different than expected');

      expect(results[1].value, '1: 2',
          reason: 'The result of simpleTask is different than expected');

      expect(results[2].value, '1: 2',
          reason: 'The result of simpleTask is different than expected');

      expect(results[0].hashCode, results[1].hashCode,
          reason: 'The execution of request 1 was not shared with request 2');

      expect(results[0].hashCode, results[2].hashCode,
          reason: 'The execution of request 1 was not shared with request 3');
    });

    test('2 not concurrent executions', () async {
      final resolver = SharedResultResolver(managerId: 'test', taskId: '1');

      final result1 = resolver.executeTask(
        callerReference: '2 not concurrent executions',
        task: (status) => simpleTaskCalculator(taskId: '1', number: '1'),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final result2 = resolver.executeTask(
        callerReference: '2 not concurrent executions',
        task: (status) => simpleTaskCalculator(taskId: '1', number: '2'),
      );

      final results = await Future.wait([result1, result2]);

      expect(results.first.hashCode, isNot(equals(results.last.hashCode)),
          reason: 'The execution of request 1 was shared with request 2');

      expect(results.first.value, '1: 2',
          reason: 'The result of simpleTask is different than expected');

      expect(results.last.value, '1: 3',
          reason: 'The result of simpleTask is different than expected');
    });

    test('cached execution', () async {
      final resolver =
          SharedResultResolver<DateTime>(managerId: 'test', taskId: '1');

      final future1 = resolver.executeTask(
        callerReference: 'cached execution',
        cacheDuration: taskDuration * 2,
        task: (status) async {
          final startedAt = DateTime.now();
          Future.delayed(taskDuration);
          return startedAt;
        },
      );

      await Future.delayed(halfTaskDuration);

      final future2 = resolver.executeTask(
        callerReference: 'cached execution',
        task: (status) async {
          final startedAt = DateTime.now();
          Future.delayed(taskDuration);
          return startedAt;
        },
      );

      final results1 = await Future.wait([future1, future2]);

      expect(results1.length, 2);
      expect(results1.first, results1.last);

      final future3 = resolver.executeTask(
        callerReference: 'cached execution',
        task: (status) async {
          final startedAt = DateTime.now();
          Future.delayed(taskDuration);
          return startedAt;
        },
      );

      final result3 = await future3;
      expect(results1.first, result3);

      await Future.delayed(taskDuration * 2);

      final future4 = resolver.executeTask(
        callerReference: 'cached execution',
        task: (status) async {
          final startedAt = DateTime.now();
          Future.delayed(taskDuration);
          return startedAt;
        },
      );

      final result4 = await future4;

      expect(result3, isNot(result4));
    });
  });
}
