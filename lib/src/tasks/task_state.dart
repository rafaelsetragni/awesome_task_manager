import 'dart:async';
import 'dart:developer' as dev;

import '../../awesome_task_manager.dart';

/// Base mutable representation of a task’s internal status lifecycle.
///
/// A [TaskState] tracks core task metadata including execution progress,
/// cancellation, timeout, handled errors, and the final result value. While
/// internal and mutable, it exposes an immutable external view through
/// [TaskStatus], which is emitted to observers via streams.
///
/// Concrete task implementations such as [CancelableTask] extend this class.
abstract class TaskState<T> {
  final String managerId, taskId;
  final Completer<T> completer;

  final void Function(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    int level,
    String name,
    Zone? zone,
    Object? error,
    StackTrace? stackTrace,
  }) customDevLog;

  bool _isError = false;
  bool _executed = false;
  bool _isTimedOut = false;
  bool _isCanceled = false;
  Exception? _lastException;
  T? _result;

  late final TaskStatus<T> status;

  /// Creates a task state instance identified by [managerId] and [taskId].
  ///
  /// Initializes the result [Future] and attaches handlers for capturing results
  /// or exceptions. Each mutation to internal flags triggers [emitNewState] to
  /// notify observers of updated task status.
  TaskState(
      {required this.managerId,
      required this.taskId,
      this.customDevLog = dev.log})
      : completer = Completer() {
    status = TaskStatus(this);
    completer.future
        // Capture the last value returned
        .then(onNewResult)
        // avoids the error to reach the highest level if
        // there is no listeners when canceled
        .catchError(
          onNewException,
          test: (_) => true,
        );
  }

  /// Returns the [Future] representing the final result of this task.
  ///
  /// All callers receive the same future instance, ensuring shared completion.
  Future<T> get future => completer.future;

  /// Whether the task has been explicitly cancelled before completion.
  bool get isCanceled => _isCanceled;

  /// Whether the task exceeded its configured timeout duration.
  bool get isTimedOut => _isTimedOut;

  /// Whether the task is currently executing and has not yet finished.
  bool get isExecuting => _executed && !isCompleted;

  /// Whether the task finished with an error that was not caused by timeout.
  bool get isError => _isError;

  /// Whether the task has reached a terminal state — completed, cancelled,
  /// timed out, or errored. No further transitions are possible once completed.
  bool get isCompleted =>
      completer.isCompleted || _isCanceled || _isTimedOut || _isError;

  /// The last exception captured during execution, if any.
  ///
  /// May be `null` if the task has not failed.
  Exception? get lastException => _lastException;

  /// The computed result of the task if successfully completed.
  ///
  /// Returns `null` when the task has no result or did not complete successfully.
  T? get result => _result;

  set isError(bool value) {
    _isError = value;
    emitNewState();
  }

  set started(bool value) {
    _executed = value;
    emitNewState();
  }

  set isTimedOut(bool value) {
    _isTimedOut = value;
    emitNewState();
  }

  set isCanceled(bool value) {
    _isCanceled = value;
    emitNewState();
  }

  /// Callback invoked whenever the task returns a final value.
  ///
  /// Used internally to store the result and propagate state.
  FutureOr<dynamic> onNewResult(T lastValue) {
    _result = lastValue;
    return null;
  }

  /// Callback invoked whenever an exception is thrown during execution.
  ///
  /// Captures the last exception, logs the error, and prevents error propagation
  /// beyond task-level scope when unobserved.
  FutureOr<dynamic> onNewException(dynamic e) {
    if (e is Exception) {
      _lastException = e;
    }
    customDevLog(e.toString(), name: taskId);
    return null;
  }

  /// Emits the latest immutable [TaskStatus] snapshot to all relevant observers.
  ///
  /// This triggers updates on:
  ///  * the per-task stream for [taskId]
  ///  * the per-manager stream for [managerId]
  ///  * the global task status stream
  ///
  /// Called automatically whenever internal execution state changes—such as start,
  /// completion, cancellation, timeout, or error—to notify UI or listeners in real time.
  void emitNewState() => TaskManager.emitNewTaskState(taskStatus: status);

  /// Provides a readable debug representation of the task’s current state.
  ///
  /// Useful for logging, debugging and tracing task lifecycle transitions.
  @override
  String toString() => 'TaskState<$T>('
      'taskId: $taskId, '
      'isCanceled: $isCanceled, '
      'isTimedOut: $isTimedOut, '
      'isExecuting: $isExecuting, '
      'isError: $isError, '
      'lastException: ${_lastException?.toString() ?? "None"}, '
      'result: ${_result?.toString() ?? "None"}, '
      'isCompleted: $isCompleted'
      ')';
}
