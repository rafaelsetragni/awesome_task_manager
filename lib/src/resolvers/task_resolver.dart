import 'dart:async';
import 'dart:collection';

import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';

import '../types/types.dart';

/// Base class responsible for coordinating execution flow for tasks that share a logical identifier.
///
/// A [TaskResolver] defines how tasks are scheduled, queued, executed, cancelled, or reused,
/// depending on the concurrency strategy implemented in concrete subclasses
/// such as [SharedResultResolver], [SequentialQueueResolver], [TaskPoolResolver],
/// [CancelPreviousResolver], and [RejectAfterThresholdResolver].
///
/// Each resolver maintains a queue of tasks and ensures that execution order and
/// concurrency rules are respected according to its strategy.
abstract class TaskResolver<T> {
  /// Unique identifiers used to group related tasks under the same execution domain.
  ///
  /// [managerId] differentiates higher-level task groups,
  /// while [taskId] identifies a specific task within that group.
  final String managerId, taskId;

  /// Creates a [TaskResolver] with identifiers used to associate tasks
  /// to a logical group handled by a specific manager.
  ///
  /// The [managerId] is used for higher-level categorization of task groups,
  /// while [taskId] identifies the specific task within that group.
  ///
  /// Concrete resolvers use these identifiers to coordinate execution flow,
  /// concurrency constraints, and lifecycle management across related tasks.
  TaskResolver({required this.managerId, required this.taskId});

  /// The resolver decides how items in the queue are scheduled and resolved.
  final Queue<CancelableTask<T>> taskQueue = Queue();

  /// Returns a [Stopwatch] instance used to measure and log execution time.
  ///
  /// Can be overridden in tests to simulate time passage deterministically.
  Stopwatch getStopwatch() => Stopwatch();

  /// Validates that a concurrency limit argument is valid (>= 1).
  ///
  /// Throws [InvalidTasksParameterException] if validation fails.
  void validateMaximumParallelTasks(int maximumParallelTasks) {
    if (maximumParallelTasks >= 1) return;
    throw InvalidTasksParameterException(
        parameterName: 'maximumParallelTasks', value: maximumParallelTasks);
  }

  /// Tracks the number of currently running tasks.
  ///
  /// Concrete resolvers update this counter to enforce concurrency rules.
  int _tasksRunning = 0;
  int get tasksRunning => _tasksRunning;

  /// Executes a single [CancelableTask] instance, handling lifecycle, timing,
  /// logging, and exception capturing.
  ///
  /// Logs start, finish, error states, and execution duration via [AwesomeTaskManager.log].
  ///
  /// Returns a [TaskResult] containing either a successful result or the thrown exception.
  Future<TaskResult<T>> executeSingleTask({
    required String tag,
    required CancelableTask<T> cancelableTaskReference,
  }) async {
    int taskIncrement = cancelableTaskReference.isCompleted ? 0 : 1;
    // Begin execution measurement to report performance metrics.
    var stopWatch = getStopwatch()..start();
    if (taskIncrement > 0) {
      AwesomeTaskManager().log('[$taskId] Task started', name: tag);
    }
    try {
      _tasksRunning += taskIncrement;
      T? finalValue = await cancelableTaskReference.execute();
      // Successful completion: return value with no exception.
      return (result: finalValue, exception: null);
    } on Exception catch (e) {
      if (taskIncrement > 0) {
        AwesomeTaskManager()
            .log('[$taskId] Task encountered an error: $e', name: tag);
      }
      return (result: null, exception: e);
    } catch (e) {
      if (taskIncrement > 0) {
        AwesomeTaskManager()
            .log('[$taskId] Task encountered an error: $e', name: tag);
      }
      return (result: null, exception: Exception(e));
    } finally {
      // Cleanup phase: update counters and report completion time.
      _tasksRunning -= taskIncrement;
      stopWatch.stop();
      if (taskIncrement > 0) {
        AwesomeTaskManager().log(
            '[$taskId] Task finished in ${stopWatch.elapsed.humanString}',
            name: tag);
      }
    }
  }

  /// Attempts to locate the next pending task in the queue and execute it,
  /// preserving fairness and correct sequential resolution order.
  ///
  /// If no pending task is found, re-executes the finished reference to ensure
  /// state consistency for listeners awaiting completion.
  Future<TaskResult<T>> fetchNextQueue({
    required String callerReference,
    required CancelableTask<T> finishedTask,
  }) async {
    taskQueue.removeWhere((CancelableTask<T> e) => e == finishedTask);
    for (CancelableTask<T> nextTask in taskQueue) {
      if (nextTask.isExecuting || nextTask.isCompleted) continue;
      return executeSingleTask(
        tag: callerReference,
        cancelableTaskReference: nextTask,
      );
    }

    return executeSingleTask(
      tag: callerReference,
      cancelableTaskReference: finishedTask,
    );
  }

  /// Attempts to cancel a task currently tracked in the queue.
  ///
  /// Returns `true` if a matching task was found and successfully cancelled,
  /// otherwise returns `false`.
  bool cancelTask({required String taskId}) {
    CancelableTask? locatedTask;
    for (CancelableTask task in taskQueue) {
      if (task.taskId == taskId) {
        locatedTask = task;
        break;
      }
    }
    return locatedTask?.cancel() ?? false;
  }
}
