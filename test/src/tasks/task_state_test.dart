import 'package:awesome_task_manager/src/tasks/task_state.dart';
import 'package:flutter_test/flutter_test.dart';

// Concrete implementation for testing since TaskState is abstract
class _TestTaskState<T> extends TaskState<T> {
  _TestTaskState({required super.managerId, required super.taskId});

  // By overriding emitNewState to do nothing, we fulfill the user's request
  // to ignore this method for now.
  @override
  void emitNewState() {}
}

void main() {
  group('TaskState', () {
    const managerId = 'manager';
    const taskId = 'task';

    test('initial state is correct', () {
      final taskState =
          _TestTaskState<String>(managerId: managerId, taskId: taskId);

      expect(taskState.isCanceled, isFalse);
      expect(taskState.isTimedOut, isFalse);
      expect(taskState.isExecuting, isFalse);
      expect(taskState.isError, isFalse);
      expect(taskState.isCompleted, isFalse);
      expect(taskState.lastException, isNull);
      expect(taskState.result, isNull);
      expect(taskState.managerId, managerId);
      expect(taskState.taskId, taskId);
    });

    test('setting started to true updates isExecuting', () {
      final taskState =
          _TestTaskState<String>(managerId: managerId, taskId: taskId);
      taskState.started = true;
      expect(taskState.isExecuting, isTrue);
      expect(taskState.isCompleted, isFalse); // Not completed yet
    });

    test('setting isCanceled to true updates isCanceled and isCompleted', () {
      final taskState =
          _TestTaskState<String>(managerId: managerId, taskId: taskId);
      taskState.isCanceled = true;
      expect(taskState.isCanceled, isTrue);
      expect(taskState.isCompleted, isTrue);
    });

    test('setting isTimedOut to true updates isTimedOut and isCompleted', () {
      final taskState =
          _TestTaskState<String>(managerId: managerId, taskId: taskId);
      taskState.isTimedOut = true;
      expect(taskState.isTimedOut, isTrue);
      expect(taskState.isCompleted, isTrue);
    });

    test('setting isError to true updates isError and isCompleted', () {
      final taskState =
          _TestTaskState<String>(managerId: managerId, taskId: taskId);
      taskState.isError = true;
      expect(taskState.isError, isTrue);
      expect(taskState.isCompleted, isTrue);
    });

    test('completing the completer updates result and isCompleted', () async {
      final taskState =
          _TestTaskState<String>(managerId: managerId, taskId: taskId);
      taskState.started = true;
      const testResult = 'success';

      taskState.completer.complete(testResult);
      await taskState.future; // wait for future to complete

      expect(taskState.result, testResult);
      expect(taskState.isCompleted, isTrue);
      expect(taskState.isExecuting, isFalse);
    });

    test(
        'completing the completer with an error updates lastException and isCompleted',
        () async {
      final taskState =
          _TestTaskState<String>(managerId: managerId, taskId: taskId);
      taskState.started = true;
      final testException = Exception('Test Error');

      taskState.completer.completeError(testException);

      try {
        await taskState.future;
      } catch (e) {
        // Catch the expected exception
      }

      expect(taskState.lastException, testException);
      expect(taskState.isError, isFalse); // isError is manually set
      expect(taskState.isCompleted, isTrue);
      expect(taskState.isExecuting, isFalse);
    });

    test('isCompleted is true when completer.isCompleted', () {
      final taskState =
          _TestTaskState<String>(managerId: managerId, taskId: taskId);
      taskState.completer.complete('done');
      expect(taskState.isCompleted, isTrue);
    });

    test('toString returns a correct representation', () async {
      final taskState =
          _TestTaskState<String>(managerId: managerId, taskId: taskId);

      const testResult = 'success';
      await taskState.onNewResult(testResult);

      final expectedString = 'TaskState<String>('
          'taskId: $taskId, '
          'isCanceled: false, '
          'isTimedOut: false, '
          'isExecuting: false, '
          'isError: false, '
          'lastException: None, '
          'result: $testResult, '
          'isCompleted: false'
          ')';

      expect(taskState.toString(), expectedString);
    });
  });
}
