import 'dart:async';

import 'package:awesome_task_manager/src/resolvers/cancel_previous_resolver.dart';
import 'package:awesome_task_manager/src/resolvers/reject_after_threshold_resolver.dart';
import 'package:awesome_task_manager/src/resolvers/sequential_queue_resolver.dart';
import 'package:awesome_task_manager/src/resolvers/shared_result_resolver.dart';

import '../../awesome_task_manager.dart';

class SharedResultManager extends TaskManager {
  final String managerId;

  SharedResultManager({
    required this.managerId,
  });

  Future<TaskResult<T>> executeTaskSharingResult<T>({
    required String callerReference,
    required String taskId,
    required Task<T> task,
    Duration cacheDuration = Duration.zero,
    Duration? timeoutDuration,
  }) {
    final SharedResultResolver<T> resolver = getResolver<T>(
        taskId: taskId,
        factory: () => SharedResultResolver<T>(
              managerId: managerId,
              taskId: taskId,
            )) as SharedResultResolver<T>;

    resolverTypes[taskId] = T;
    return resolver.executeTask(
      callerReference: callerReference,
      task: task,
      cacheDuration: cacheDuration,
      timeoutDuration: timeoutDuration,
    );
  }
}

class SequentialQueueManager extends TaskManager {
  final String managerId;

  SequentialQueueManager({
    required this.managerId,
  });

  Future<TaskResult<T>> executeSequentialTask<T>({
    required String callerReference,
    required String taskId,
    required Task<T> task,
    int maximumParallelTasks = 1,
    Duration? timeoutDuration,
  }) {
    final SequentialQueueResolver<T> resolver = getResolver<T>(
        taskId: taskId,
        factory: () => SequentialQueueResolver<T>(
              managerId: managerId,
              taskId: taskId,
              maximumParallelTasks: maximumParallelTasks,
            )) as SequentialQueueResolver<T>;

    resolverTypes[taskId] = T;
    return resolver.executeTask(
        callerReference: callerReference,
        task: task,
        timeoutDuration: timeoutDuration);
  }
}

class TaskPoolManager extends TaskManager {
  final String managerId;
  final int poolSize;

  TaskPoolManager({
    required this.poolSize,
    required this.managerId,
  });

  Future<TaskResult<T>> executeTaskInPool<T>({
    required String callerReference,
    required String taskId,
    required Task<T> task,
    Duration? timeoutDuration,
  }) {
    final SequentialQueueResolver<T> resolver = getResolver<T>(
        taskId: taskId,
        factory: () => SequentialQueueResolver<T>(
              managerId: managerId,
              taskId: taskId,
              maximumParallelTasks: poolSize,
            )) as SequentialQueueResolver<T>;

    resolverTypes[taskId] = T;

    return resolver.executeTask(
        callerReference: callerReference,
        task: task,
        timeoutDuration: timeoutDuration);
  }
}

class RejectedAfterThresholdManager extends TaskManager {
  final String managerId;
  final int taskThreshold;

  RejectedAfterThresholdManager({
    required this.taskThreshold,
    required this.managerId,
  });

  Future<TaskResult<T>> executeRejectingAfterThreshold<T>({
    required String callerReference,
    required String taskId,
    required Task<T> task,
    Duration timeoutDuration = Duration.zero,
  }) {
    final RejectAfterThresholdResolver<T> resolver = getResolver<T>(
        taskId: taskId,
        factory: () => RejectAfterThresholdResolver<T>(
              managerId: managerId,
              taskId: taskId,
              taskThreshold: taskThreshold,
            )) as RejectAfterThresholdResolver<T>;

    resolverTypes[taskId] = T;

    return resolver.executeTask(
      callerReference: callerReference,
      task: task,
    );
  }
}

class CancelPreviousTaskManager extends TaskManager {
  final String managerId;
  final int maximumParallelTasks;

  CancelPreviousTaskManager({
    required this.maximumParallelTasks,
    required this.managerId,
  });

  Future<TaskResult<T>> executeCancellingPreviousTask<T>({
    required String callerReference,
    required String taskId,
    required Task<T> task,
    Duration? timeoutDuration,
  }) {
    final CancelPreviousResolver<T> resolver = getResolver<T>(
        taskId: taskId,
        factory: () => CancelPreviousResolver<T>(
              managerId: managerId,
              taskId: taskId,
              maximumParallelTasks: maximumParallelTasks,
            )) as CancelPreviousResolver<T>;

    resolverTypes[taskId] = T;
    return resolver.executeTask(
      callerReference: callerReference,
      task: task,
      timeoutDuration: timeoutDuration,
    );
  }
}
