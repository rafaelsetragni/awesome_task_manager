import 'dart:async';

import 'package:awesome_task_manager/src/resolvers/task_resolver.dart';
import 'package:awesome_task_manager/src/types/types.dart';

import '../tasks/cancelable_task.dart';

class CancelPreviousResolver<T> extends TaskResolver<T> {
  int maximumParallelTasks;

  CancelPreviousResolver({
    required super.managerId,
    required super.taskId,
    required this.maximumParallelTasks,
  }) {
    validateMaximumParallelTasks(maximumParallelTasks);
  }

  Future<TaskResult<T>> executeTask({
    required String callerReference,
    required Task<T> task,
    Duration? timeoutDuration,
  }) {
    if (tasksRunning >= maximumParallelTasks) {
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
