import 'dart:async';

import '../exceptions/task_exceptions.dart';
import '../types/types.dart';
import 'task_state.dart';

/// Represents a single executable task that supports cancellation and timeout behavior.
///
/// A [CancelableTask] encapsulates a [Task] function and tracks its execution
/// lifecycle including start time, completion, cancellation, timeout, and errors.
/// This enables fine-grained task coordination within task resolvers.
class CancelableTask<T> extends TaskState<T> {
  /// Optional duration specifying the maximum allowed execution time.
  ///
  /// If the timeout is reached before completion, the task is marked as timed out
  /// and a [TimeoutException] is thrown.
  final Duration? timeout;

  /// The asynchronous function representing the actual work to be executed.
  ///
  /// The function receives a [TaskStatus] snapshot and returns a result of type [T].
  final Task<T> task;

  /// Creates a cancelable task bound to a specific [managerId] and [taskId].
  ///
  /// Can be configured with an optional [timeout] to limit execution duration.
  CancelableTask({
    required super.managerId,
    required super.taskId,
    required this.task,
    this.timeout,
  });

  /// Attempts to cancel the execution of this task.
  ///
  /// If cancellation succeeds, future listeners receive a [CancellationException].
  /// Returns `false` if the task has already finished execution.
  bool cancel() {
    if (isCompleted) return false;
    try {
      completer.completeError(CancellationException(taskId: taskId));
      return isCanceled = true;
    } catch (_) {
      return false;
    }
  }

  /// Executes the task if it has not already started or completed.
  ///
  /// If [timeout] is provided, execution is wrapped and monitored accordingly.
  /// On success, the result is completed into the internal completer.
  /// On failure, the thrown exception is propagated through the result future.
  ///
  /// Returns the same [Future] instance to all callers.
  Future<T> execute() async {
    if (isCompleted || isExecuting) return future;
    // Mark as executing before running the task.
    started = true;

    try {
      final timeout = this.timeout;
      late final Future<T> future;
      if (timeout == null) {
        future = task(status);
      } else {
        future = task(status).timeout(timeout, onTimeout: () {
          isTimedOut = true;
          throw TimeoutException(taskId: taskId);
        });
      }

      // Normal successful completion; publish result through completer.
      completer.complete(await future);
      emitNewState();
    } catch (error) {
      // Mark task as failed unless timeout was the cause.
      isError = !isTimedOut;
      if (!completer.isCompleted) {
        completer.completeError(error);
        emitNewState();
      }
    }
    // Always return the shared result future.
    return future;
  }
}
