import 'dart:async';

import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/streams/observable_stream.dart';

import '../resolvers/task_resolver.dart';

abstract class TaskManager {
  static final ObservableStream<TaskStatus> allTasksStream = ObservableStream();
  static final Map<String, ObservableStream<TaskStatus>>
      taskStreamsByManagerId = {}, taskStreamsByTaskId = {};

  static void emitNewTaskState({required TaskStatus taskStatus}) {
    taskStreamsByManagerId[taskStatus.managerId]?.add(taskStatus);
    taskStreamsByTaskId[taskStatus.taskId]?.add(taskStatus);
    allTasksStream.add(taskStatus);
  }

  static ObservableStream<TaskStatus> getStreamControllerByTaskId({
    String? taskId,
  }) {
    final finalTaskId = taskId?.toLowerCase().trim();
    if (finalTaskId == null) return allTasksStream;
    final ObservableStream<TaskStatus> controller =
        taskStreamsByTaskId[finalTaskId] ??= ObservableStream();
    return controller;
  }

  static Stream<TaskStatus<dynamic>?> getManagerStatusStream(
      {String? managerId}) {
    final finalTaskId = managerId?.toLowerCase().trim();
    if (finalTaskId == null) return allTasksStream.stream;
    final ObservableStream<TaskStatus> controller =
        taskStreamsByManagerId[finalTaskId] ??= ObservableStream();
    return controller.stream;
  }

  static Stream<TaskStatus?> getStatusStream<T>({String? taskId}) =>
      getStreamControllerByTaskId(taskId: taskId).stream;

  final Map<String, TaskResolver> taskResolvers = {};
  final Map<String, Type> resolverTypes = {};

  void resetManager() {
    taskStreamsByTaskId
      ..forEach((k, v) => v.close())
      ..clear();
    taskResolvers.clear();
    resolverTypes.clear();
  }

  TaskResolver<T> getResolver<T>({
    required String taskId,
    required TaskResolver<T> Function() factory,
  }) {
    TaskResolver resolver = taskResolvers[taskId] ??= factory();
    if (resolver is TaskResolver<T>) {
      getStreamControllerByTaskId(taskId: taskId);
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
