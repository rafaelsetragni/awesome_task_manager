import 'dart:async';

import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/streams/observable_stream.dart';

import '../resolvers/task_resolver.dart';

abstract class TaskManager {
  static final Map<String, ObservableStream<TaskStatus>> taskStreams = {};

  static void emitNewTaskState({required TaskStatus taskStatus}) {
    taskStreams[taskStatus.taskId]?.add(taskStatus);
    taskStreams['']?.add(taskStatus);
  }

  static ObservableStream<TaskStatus> getStreamController({
    String? taskId,
  }){
    final finalTaskId = taskId ?? '';
    final controller =
        taskStreams[finalTaskId] ??= ObservableStream<TaskStatus>(
          initialValue: TaskStatus.empty(taskId: finalTaskId)
        );
    return controller;
  }

  static Stream<TaskStatus> getStatusStream<T>({String? taskId}) =>
      getStreamController(taskId: taskId).stream;

  final Map<String, TaskResolver> taskResolvers = {};
  final Map<String, Type> resolverTypes = {};

  void resetManager(){
    taskStreams.clear();
    taskResolvers.clear();
    resolverTypes.clear();
  }

  TaskResolver<T> getResolver<T>({
    required String taskId,
    required TaskResolver<T> Function() factory,
  }) {
    TaskResolver resolver =
    taskResolvers[taskId] ??= factory();
    if (resolver is TaskResolver<T>) {
      getStreamController(taskId: taskId);
      return resolver;
    }
    Type typeB = resolverTypes[taskId]!;
    throw MismatchTasksReturnsException(
      taskId: taskId,
      typeA: T,
      typeB: typeB,
    );
  }
}
