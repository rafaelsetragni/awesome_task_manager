import 'package:awesome_task_manager/src/exceptions/task_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvalidTasksParameterException', () {
    test('InvalidTasksParameterException - exception message', () async {
      expect(
          InvalidTasksParameterException(
            parameterName: 'limit',
            value: null,
          ).toString(),
          'InvalidTasksParameterException: Parameter value of limit is invalid (null)');
      expect(
          InvalidTasksParameterException(
            parameterName: 'limit',
            value: '1',
          ).toString(),
          'InvalidTasksParameterException: Parameter value of limit is invalid (1)');
      expect(
          InvalidTasksParameterException(
            parameterName: 'limit',
            value: 1,
          ).toString(),
          'InvalidTasksParameterException: Parameter value of limit is invalid (1)');
    });
  });

  group('TooManyTasksException', () {
    test('TooManyTasksException - exception message', () async {
      expect(TooManyTasksException('1').toString(),
          'TooManyTasksException: Too many tasks in execution for 1');
    });
  });

  group('MismatchTasksReturnsException', () {
    test('MismatchTasksReturnsException - exception message', () async {
      expect(
          MismatchTasksReturnsException(
            taskId: 'Task 1',
            typeA: String,
            typeB: dynamic,
          ).toString(),
          'MismatchTasksReturnsException: Tasks with same ID Task 1 are requesting'
          ' different return types'
          ' (A return: String, B return: dynamic)');
    });
  });

  group('TimeoutException', () {
    test('TimeoutException - exception message', () async {
      expect(TimeoutException(taskId: '1').toString(),
          'TimeoutException: The task 1 has timed out.');
    });
  });

  group('CancellationException', () {
    test('CancellationException - exception message', () async {
      expect(CancellationException(taskId: '1').toString(),
          'CancellationException: The task 1 was cancelled.');
    });
  });
}
