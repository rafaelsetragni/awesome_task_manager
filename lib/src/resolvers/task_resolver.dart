import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;

import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';

import '../types/types.dart';

abstract class TaskResolver<T> {
  final String taskId;

  TaskResolver({required this.taskId});

  final Queue<CancelableTask<T>> taskQueue = Queue();
  Stopwatch getStopwatch() =>
      Stopwatch();

  void validateMaximumParallelTasks(int maximumParallelTasks){
    if(maximumParallelTasks >= 1) return;
    throw InvalidTasksParameterException(
        parameterName: 'maximumParallelTasks', value: maximumParallelTasks);
  }

  int _tasksRunning = 0;
  int get tasksRunning => _tasksRunning;
  Future<TaskResult<T>> executeSingleTask({
    required String tag,
    required CancelableTask<T> cancelableTaskReference,
  }) async {
    int taskIncrement = cancelableTaskReference.isCompleted ? 0 : 1;
    var stopWatch = getStopwatch()..start();
    if (taskIncrement > 0) {
      dev.log('[$taskId] Task started', name: tag);
    }
    try {
      _tasksRunning += taskIncrement;
      T? finalValue = await cancelableTaskReference.execute();
      return (result: finalValue, exception: null);
    } on Exception catch (e) {
      if (taskIncrement > 0) {
        dev.log('[$taskId] Task encountered an error: $e', name: tag);
      }
      return (result: null, exception: e);
    } catch (e) {
      if (taskIncrement > 0) {
        dev.log('[$taskId] Task encountered an error: $e', name: tag);
      }
      return (result: null, exception: Exception(e));
    } finally {
      _tasksRunning -= taskIncrement;
      stopWatch.stop();
      if (taskIncrement > 0) {
        dev.log('[$taskId] Task finished in ${stopWatch.elapsed.humanString}',
            name: tag);
      }
    }
  }

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

  bool cancelTask({required String taskId}){
    CancelableTask? locatedTask;
    for(CancelableTask task in taskQueue){
      if (task.taskId == taskId) {
        locatedTask = task;
        break;
      }
    }
    return locatedTask?.cancel() ?? false;
  }
}