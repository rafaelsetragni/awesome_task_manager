import 'dart:async';

import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/resolvers/task_resolver.dart';
import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';
import 'package:awesome_task_manager/src/types/types.dart';

/// A task resolver that enforces a strict concurrency threshold per [taskId].
///
/// When the number of queued or executing tasks reaches [taskThreshold],
/// additional incoming tasks are immediately rejected rather than queued.
///
/// This strategy is useful for protecting critical resources, preventing overload,
/// and enforcing strict operational constraints such as hardware access limits,
/// external rate-limited API calls, or safety-critical operations.
class RejectAfterThresholdResolver<T> extends TaskResolver<T> {
  /// Maximum number of tasks allowed to execute or remain in queue simultaneously.
  ///
  /// Incoming tasks beyond this threshold are rejected immediately.
  final int taskThreshold;

  /// Creates a resolver that rejects new tasks if the number of queued or executing
  /// tasks reaches [taskThreshold].
  ///
  /// Throws [ArgumentError] if [taskThreshold] is less than 1.
  RejectAfterThresholdResolver({
    required super.managerId,
    required super.taskId,
    required this.taskThreshold,
  }) {
    validateMaximumParallelTasks(taskThreshold);
  }

  /// {@inheritdoc}
  ///
  /// If the queue length reaches [taskThreshold], this method rejects the request,
  /// logs an event, and returns a [TaskResult] containing `null` and a
  /// [TooManyTasksException].
  ///
  /// Otherwise, schedules the task for execution and manages cleanup after completion.
  Future<TaskResult<T>> executeTask(
      {required String callerReference, required Task<T> task}) async {
    if (taskQueue.length >= taskThreshold) {
      AwesomeTaskManager().log('$taskId: task rejected', name: callerReference);
      return Future.value(
          (result: null, exception: TooManyTasksException(taskId)));
    }

    CancelableTask<T> completer = CancelableTask(
      managerId: managerId,
      taskId: taskId,
      task: task,
    );
    taskQueue.add(completer);

    return executeSingleTask(
      tag: callerReference,
      cancelableTaskReference: completer,
    ).whenComplete(() {
      fetchNextQueue(
        callerReference: callerReference,
        finishedTask: completer,
      );
    });
  }
}
