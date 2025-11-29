import 'dart:async';

import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';

import '../repositories/cache_repository.dart';
import '../repositories/memory_repository.dart';
import 'task_resolver.dart';

/// A task resolver that executes a task only once per [taskId] and shares
/// the resulting value among all concurrent callers.
///
/// If a task is already executing when another request arrives, the new caller
/// waits for the same result rather than scheduling an additional execution.
/// This prevents duplicated operations such as repeated network calls.
///
/// The resolver optionally caches successful results for a defined [cacheDuration],
/// returning them immediately for subsequent requests while the cache remains valid.
///
/// Useful for scenarios such as configuration loading, authentication tokens,
/// or expensive remote operations that should not run more than once simultaneously.
class SharedResultResolver<T> extends TaskResolver<T> {
  /// Cache repository used to optionally store and reuse previously resolved results.
  ///
  /// Defaults to an in-memory cache when no custom repository is provided.
  final CacheRepository cache;

  /// Creates a [SharedResultResolver] instance.
  ///
  /// If [cacheRepository] is provided, cached values persist based on the selected backend.
  /// Otherwise, a default in-memory implementation ([MemoryRepository]) is used.
  SharedResultResolver({
    required super.managerId,
    required super.taskId,
    CacheRepository? cacheRepository,
  }) : cache = cacheRepository ?? MemoryRepository();

  /// Execution flow:
  /// 1. If a valid cached value exists, returns it immediately without executing the task.
  /// 2. If an execution is already in progress, attaches the caller to the existing task.
  /// 3. Otherwise, initiates a new execution, stores the result in cache if applicable,
  ///    and shares the completion response with all waiting callers.
  ///
  /// The [cacheDuration] determines how long the result may be reused.
  /// A duration of `Duration.zero` disables caching.
  Future<TaskResult<T>> executeTask({
    required String callerReference,
    required Task<T> task,
    Duration cacheDuration = Duration.zero,
    Duration? timeoutDuration,
  }) async {
    final lastCache = await cache.read<T>(key: taskId);
    if (lastCache?.$2.isAfter(DateTime.now()) ?? false) {
      return TaskResult(result: lastCache?.$1, exception: null);
    }

    final lastFuture = taskQueue.firstOrNull;
    if (lastFuture != null) {
      final lastTask = taskQueue.last;
      AwesomeTaskManager()
          .log('future shared (${lastFuture.hashCode})', name: callerReference);
      return executeSingleTask(
        tag: callerReference,
        cancelableTaskReference: lastTask,
      );
    }

    CancelableTask<T> completer = CancelableTask(
      managerId: managerId,
      taskId: taskId,
      task: task,
    );
    // Register the new task so additional callers can share its eventual result.
    taskQueue.add(completer);

    return executeSingleTask(
      tag: callerReference,
      cancelableTaskReference: completer,
    ).then((taskResult) {
      T? value = taskResult.result;
      if (value != null && cacheDuration != Duration.zero) {
        cache.write<T>(
            key: taskId,
            value: value,
            expirationDate: DateTime.now().add(cacheDuration));
      }
      fetchNextQueue(
        callerReference: callerReference,
        finishedTask: completer,
      );
      return taskResult;
    });
  }
}
