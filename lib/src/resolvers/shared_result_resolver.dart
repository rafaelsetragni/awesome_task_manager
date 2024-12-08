import 'dart:async';
import 'dart:developer' as dev;

import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';

import '../repositories/cache_repository.dart';
import '../repositories/memory_repository.dart';
import '../types/types.dart';
import 'task_resolver.dart';

class SharedResultResolver<T> extends TaskResolver<T> {

  final CacheRepository cache;

  SharedResultResolver({
    required super.taskId,
    CacheRepository? cacheRepository,
  }) :
        cache = cacheRepository ?? MemoryRepository();

  Future<TaskResult<T>> executeTask({
    required String callerReference,
    required Task<T> task,
    Duration cacheDuration = Duration.zero,
    Duration? timeoutDuration,
  }) async {
    final lastCache = await cache.read<T>(key: taskId);
    if (lastCache?.$2.isAfter(DateTime.now()) ?? false){
      return (result: lastCache?.$1, exception: null);
    }

    final lastFuture = taskQueue.firstOrNull;
    if (lastFuture != null) {
      final lastTask = taskQueue.last;
      dev.log(
          'future shared (${lastFuture.hashCode})',
          name: callerReference
      );
      return executeSingleTask(
        tag: callerReference,
        cancelableTaskReference: lastTask,
      );
    }

    CancelableTask<T> completer = CancelableTask(
        taskId: taskId,
        task: task
    );
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
            expirationDate: DateTime.now().add(cacheDuration)
        );
      }
      fetchNextQueue(
         callerReference: callerReference,
         finishedTask: completer,
      );
      return taskResult;
    });
  }
}