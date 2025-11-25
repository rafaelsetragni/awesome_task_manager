import 'dart:async';

import 'package:awesome_task_manager/src/resolvers/task_resolver.dart';
import 'package:awesome_task_manager/src/types/types.dart';

import '../tasks/cancelable_task.dart';

/// A task resolver that guarantees strict sequential execution of tasks that share
/// the same [taskId], processing them in the exact order they were received.
///
/// This strategy is useful when operations must not overlap and must execute in a
/// predictable, serialized manner—for example, ordered persistence updates,
/// financial operations, UI flows, or multi-step workflows.
///
/// Tasks are queued and executed one-by-one according to FIFO ordering.
/// When [maximumParallelTasks] is greater than 1, batches of tasks may run in parallel
/// while still preserving queue fairness.
class SequentialQueueResolver<T> extends TaskResolver<T> {
  /// Maximum number of tasks allowed to run in parallel.
  ///
  /// When current running tasks exceed this value, additional requests must wait
  /// in the queue until execution capacity becomes available.
  int maximumParallelTasks;

  /// Creates a [SequentialQueueResolver] with optional parallel capacity defined
  /// by [maximumParallelTasks].
  ///
  /// Throws [ArgumentError] if [maximumParallelTasks] is less than 1.
  SequentialQueueResolver({
    required super.managerId,
    required super.taskId,
    required this.maximumParallelTasks,
  }) {
    validateMaximumParallelTasks(maximumParallelTasks);
  }

  /// {@inheritdoc}
  ///
  /// Adds the new task to the internal queue and waits if the concurrency limit
  /// [maximumParallelTasks] has been reached.
  ///
  /// Once execution capacity is available, schedules the task and ensures that
  /// the next queued task is processed automatically upon completion.
  Future<TaskResult<T>> executeTask({
    required String callerReference,
    required Task<T> task,
    Duration? timeoutDuration,
  }) async {
    CancelableTask<T> completer = CancelableTask(
      managerId: managerId,
      taskId: taskId,
      task: task,
    ); // Wraps the async task in a cancelable holder to support controlled resolution.

    taskQueue.add(completer);
    if (tasksRunning >= maximumParallelTasks) {
      await completer.future;
    }

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
