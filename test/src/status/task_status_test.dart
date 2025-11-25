import 'package:awesome_task_manager/src/status/task_status.dart';
import 'package:awesome_task_manager/src/streams/observable_stream.dart';
import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';
import 'package:flutter_test/flutter_test.dart';

// A complete and simplified fake implementation of CancelableTask for testing.
class FakeCancelableTask<T> extends Fake implements CancelableTask<T> {
  @override
  final String taskId;
  @override
  final String managerId;
  @override
  final bool isCanceled;
  @override
  final bool isTimedOut;
  @override
  final bool isError;
  @override
  final bool isExecuting;
  @override
  final bool isCompleted;
  @override
  final T? result;
  @override
  final Exception? lastException;
  final int _hashCode;

  FakeCancelableTask({
    required this.taskId,
    required this.managerId,
    this.isCanceled = false,
    this.isTimedOut = false,
    this.isError = false,
    this.isExecuting = false,
    this.isCompleted = false,
    this.result,
    this.lastException,
    int hashCode = 0,
  }) : _hashCode = hashCode;

  @override
  int get hashCode => _hashCode;
}

void main() {
  group('TaskStatus Getters Test', () {
    test('should reflect canceled state', () {
      final taskStatus = TaskStatus(FakeCancelableTask<String>(
        taskId: 'task1',
        managerId: 'manager1',
        isCanceled: true,
      ));
      expect(taskStatus.isCanceled, isTrue);
    });

    test('should reflect timed out state', () {
      final taskStatus = TaskStatus(FakeCancelableTask<String>(
        taskId: 'task1',
        managerId: 'manager1',
        isTimedOut: true,
      ));
      expect(taskStatus.isTimedOut, isTrue);
    });

    test('should reflect completed state', () {
      final taskStatus = TaskStatus(FakeCancelableTask<String>(
        taskId: 'task1',
        managerId: 'manager1',
        isCompleted: true,
      ));
      expect(taskStatus.isCompleted, isTrue);
    });

    test('should reflect error state', () {
      final taskStatus = TaskStatus(FakeCancelableTask<String>(
        taskId: 'task1',
        managerId: 'manager1',
        isError: true,
      ));
      expect(taskStatus.isError, isTrue);
    });

    test('should reflect executing state', () {
      final taskStatus = TaskStatus(FakeCancelableTask<String>(
        taskId: 'task1',
        managerId: 'manager1',
        isExecuting: true,
      ));
      expect(taskStatus.isExecuting, isTrue);
    });

    test('should return correct taskId', () {
      final taskStatus = TaskStatus(FakeCancelableTask<String>(
        taskId: 'task1',
        managerId: 'manager1',
      ));
      expect(taskStatus.taskId, 'task1');
    });

    test('should return correct managerId', () {
      final taskStatus = TaskStatus(FakeCancelableTask<String>(
        taskId: 'task1',
        managerId: 'manager1',
      ));
      expect(taskStatus.managerId, 'manager1');
    });

    test('should return correct result', () {
      final taskStatus = TaskStatus(FakeCancelableTask<String>(
        taskId: 'task1',
        managerId: 'manager1',
        result: 'Success',
      ));
      expect(taskStatus.result, 'Success');
    });

    test('should return correct lastException', () {
      final exception = Exception('Test Exception');
      final taskStatus = TaskStatus(FakeCancelableTask<String>(
        taskId: 'task1',
        managerId: 'manager1',
        lastException: exception,
      ));
      expect(taskStatus.lastException, exception);
    });

    test('should return correct taskHashcode', () {
      final taskStatus = TaskStatus(FakeCancelableTask<String>(
        taskId: 'task1',
        managerId: 'manager1',
        hashCode: 42,
      ));
      expect(taskStatus.taskHashcode, 42);
    });

    test('valueOrNull returns the latest value added', () {
      final stream = ObservableStream<int>(initialValue: 10);
      stream.add(20);
      expect(stream.valueOrNull, 20);
    });
  });
}
