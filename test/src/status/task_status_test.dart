import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';
import 'package:awesome_task_manager/src/exceptions/task_exceptions.dart';
import 'package:awesome_task_manager/src/status/task_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class FakeCancelableTask<T> extends Fake implements CancelableTask<T> {
  final Future<T> _future;
  final String _taskId;
  final bool _isCanceled, _isTimedOut, _isError, _isExecuting, _isCompleted;

  FakeCancelableTask({
    required String taskId,
    required Future<T> future,
    required bool isCanceled,
    required bool isTimedOut,
    required bool isError,
    required bool isExecuting,
    required bool isCompleted,
  })  : _future = future,
        _taskId = taskId,
        _isCanceled = isCanceled,
        _isTimedOut = isTimedOut,
        _isError = isError,
        _isCompleted = isCompleted,
        _isExecuting = isExecuting;

  @override
  String get taskId => _taskId;

  @override
  Future<T> get future => _future;

  @override
  bool get isCanceled => _isCanceled;

  @override
  bool get isTimedOut => _isTimedOut;

  @override
  bool get isError => _isError;

  @override
  bool get isCompleted => _isCompleted;

  @override
  bool get isExecuting => _isExecuting;
}

void main() {
  group('TaskStatus Tests', () {
    test('Task updates when respective task is canceled', () async {
      final task = TaskStatus(FakeCancelableTask(
        taskId: 'task 1',
        future: () async {
          return '';
        }(),
        isCanceled: true,
        isCompleted: false,
        isError: false,
        isTimedOut: false,
        isExecuting: false,
      ));
      expect(task.taskId, 'task 1');
      expect(task.isCanceled, isTrue);
      expect(task.isTimedOut, isFalse);
      expect(task.isCompleted, isFalse);
      expect(task.isError, isFalse);
      expect(task.isExecuting, isFalse);
    });

    // Test other combinations
    test('Task updates when respective task is timed out', () async {
      final task = TaskStatus(FakeCancelableTask(
        taskId: 'task 1',
        future: () async {
          return '';
        }(),
        isCanceled: false,
        isCompleted: false,
        isError: false,
        isTimedOut: true,
        isExecuting: false,
      ));
      expect(task.taskId, 'task 1');
      expect(task.isCanceled, isFalse);
      expect(task.isTimedOut, isTrue);
      expect(task.isCompleted, isFalse);
      expect(task.isError, isFalse);
      expect(task.isExecuting, isFalse);
    });

    test('Task updates when respective task is completed', () async {
      final task = TaskStatus(FakeCancelableTask(
        taskId: 'task 1',
        future: () async {
          return '';
        }(),
        isCanceled: false,
        isCompleted: true,
        isError: false,
        isTimedOut: false,
        isExecuting: false,
      ));
      expect(task.taskId, 'task 1');
      expect(task.isCanceled, isFalse);
      expect(task.isTimedOut, isFalse);
      expect(task.isCompleted, isTrue);
      expect(task.isError, isFalse);
      expect(task.isExecuting, isFalse);
    });

    test('Task updates when respective task encounters an error', () async {
      final task = TaskStatus(FakeCancelableTask(
        taskId: 'task 1',
        future: () async {
          return '';
        }(),
        isCanceled: false,
        isCompleted: false,
        isError: true,
        isTimedOut: false,
        isExecuting: false,
      ));
      expect(task.taskId, 'task 1');
      expect(task.isCanceled, isFalse);
      expect(task.isTimedOut, isFalse);
      expect(task.isCompleted, isFalse);
      expect(task.isError, isTrue);
      expect(task.isExecuting, isFalse);
    });

    test('Task updates when respective task isExecuting', () async {
      final task = TaskStatus(FakeCancelableTask(
        taskId: 'task 1',
        future: () async {
          return '';
        }(),
        isCanceled: false,
        isCompleted: false,
        isError: false,
        isTimedOut: false,
        isExecuting: true,
      ));
      expect(task.taskId, 'task 1');
      expect(task.isCanceled, isFalse);
      expect(task.isTimedOut, isFalse);
      expect(task.isCompleted, isFalse);
      expect(task.isError, isFalse);
      expect(task.isExecuting, isTrue);
    });
  });
}
