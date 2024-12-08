import 'dart:async';
import 'dart:developer' as dev;

import 'package:awesome_task_manager/src/resolvers/task_resolver.dart';
import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';
import 'package:awesome_task_manager/src/types/types.dart';

import '../exceptions/task_exceptions.dart';

class RejectAfterThresholdResolver<T> extends TaskResolver<T> {
  final int taskThreshold;

  RejectAfterThresholdResolver({
    required super.taskId,
    required this.taskThreshold,
  }) {
    validateMaximumParallelTasks(taskThreshold);
  }

  Future<TaskResult<T>> executeTask({
    required String callerReference,
    required Task<T> task
  }) async {
      if (taskQueue.length >= taskThreshold) {
        dev.log('$taskId: task rejected', name: callerReference);
        return Future
            .value((result: null, exception: TooManyTasksException(taskId)));
      }

      CancelableTask<T> completer = CancelableTask(
        taskId: taskId,
        task: task,
      );
      taskQueue.add(completer);

      return executeSingleTask(
        tag: callerReference,
        cancelableTaskReference: completer,
      )
      .whenComplete(() {
        fetchNextQueue(
          callerReference: callerReference,
          finishedTask: completer,
        );
      });
  }
}