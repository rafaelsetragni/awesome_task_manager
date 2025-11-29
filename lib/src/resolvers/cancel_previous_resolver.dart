import 'dart:async';

import 'package:awesome_task_manager/src/resolvers/task_resolver.dart';

import '../../awesome_task_manager.dart';
import '../tasks/cancelable_task.dart';

/// A task resolver that automatically cancels the earliest queued task when
/// the concurrency limit [maximumParallelTasks] is reached.
///
/// This strategy ensures that only the most recent caller's task is executed,
/// discarding older tasks waiting in the queue. Useful for real-time refresh
/// behaviors such as live search suggestions, live data polling, and rapid UI updates.
///
/// Example: if the user types repeatedly, older pending tasks are cancelled and
/// only the latest computation continues.
class CancelPreviousResolver<T> extends TaskResolver<T> {
  /// Maximum allowed parallel executions for this resolver.
  ///
  /// When the number of tasks exceeds this limit, the oldest queued task is cancelled.
  int maximumParallelTasks;

  /// Creates a resolver that cancels older queued tasks once the limit of
  /// concurrently running tasks has been reached.
  ///
  /// Throws [ArgumentError] if [maximumParallelTasks] is less than 1.
  CancelPreviousResolver({
    required super.managerId,
    required super.taskId,
    required this.maximumParallelTasks,
  }) {
    validateMaximumParallelTasks(maximumParallelTasks);
  }

  /// If the queue exceeds [maximumParallelTasks], the earliest task is cancelled
  /// before the new task is scheduled. The new task is then added and executed.
  Future<TaskResult<T>> executeTask({
    required String callerReference,
    required Task<T> task,
    Duration? timeoutDuration,
  }) {
    if (tasksRunning >= maximumParallelTasks) {
      // Cancel the oldest queued task when concurrency threshold is reached.
      final firstSlot = taskQueue.firstOrNull?..cancel();
      if (firstSlot != null) {
        taskQueue.remove(firstSlot);
      }
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
