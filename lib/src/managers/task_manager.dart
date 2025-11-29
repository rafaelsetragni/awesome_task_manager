import 'dart:async';

import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/streams/observable_stream.dart';

import '../resolvers/task_resolver.dart';

/// Coordinates global task execution state and result resolution across all task managers.
///
/// This class maintains central streams for observing task status changes either
/// globally, per-task, or per-manager. It also stores instances of [TaskResolver]
/// used to execute and manage tasks efficiently.
///
/// This is an internal infrastructure component and is not typically accessed
/// directly by application code.
abstract class TaskManager {
  /// Global unified stream that emits every [TaskStatus] update from all tasks.
  ///
  /// Useful for dashboards, debug tooling, and system-wide monitoring.
  static final ObservableStream<TaskStatus> allTasksStream = ObservableStream();

  /// Map that stores per-manager task status streams.
  ///
  /// Allows consumers to listen only to relevant task updates by manager domain.
  static final Map<String, ObservableStream<TaskStatus>>
      taskStreamsByManagerId = {},

      /// Map that stores per-task status streams, keyed by [taskId].
      ///
      /// Allows isolation of visible task progress for specific tasks.
      taskStreamsByTaskId = {};

  /// Emits a new [TaskStatus] event to all relevant streams.
  ///
  /// Pushes updates to:
  /// * task-specific stream ([taskId])
  /// * manager-specific stream ([managerId])
  /// * global stream containing all task state changes
  static void emitNewTaskState({required TaskStatus taskStatus}) {
    taskStreamsByManagerId[taskStatus.managerId]?.add(taskStatus);
    taskStreamsByTaskId[taskStatus.taskId]?.add(taskStatus);
    allTasksStream.add(taskStatus);
  }

  /// Returns an [ObservableStream] controller for the given [taskId].
  ///
  /// If no stream exists yet for the given [taskId], a new one is created.
  /// If [taskId] is null, returns the global [allTasksStream].
  static ObservableStream<TaskStatus> getObservableStreamByTaskId({
    String? taskId,
  }) {
    final finalTaskId = taskId?.toLowerCase().trim();
    if (finalTaskId == null) return allTasksStream;
    final ObservableStream<TaskStatus> controller =
        taskStreamsByTaskId[finalTaskId] ??= ObservableStream();
    return controller;
  }

  /// Returns a stream of [TaskStatus] updates for tasks associated with a given [managerId].
  ///
  /// If [managerId] is null, an aggregated stream with all task updates is returned.
  static ObservableStream<TaskStatus> getObservableStreamByManagerId(
      {String? managerId}) {
    final finalTaskId = managerId?.toLowerCase().trim();
    if (finalTaskId == null) return allTasksStream;
    final ObservableStream<TaskStatus> controller =
        taskStreamsByManagerId[finalTaskId] ??= ObservableStream();
    return controller;
  }

  /// Public stream of [TaskStatus] updates scoped by [taskId] or [managerId].
  ///
  /// * Provide `taskId` to listen only to that task across all managers.
  /// * Provide `managerId` to listen to every task running within that manager.
  /// * When both are null, the global stream of all task updates is returned.
  ///
  /// This is the low-level equivalent of `AwesomeTaskManager.getTaskStatusStream`
  /// and `AwesomeTaskManager.getManagerTaskStatusStream`, suitable for
  /// integrations outside the widget layer (e.g. logging or state management).
  static Stream<TaskStatus?> getStatusStream<T>({
    String? taskId,
    String? managerId,
  }) =>
      (managerId != null
              ? getObservableStreamByManagerId(managerId: managerId)
              : getObservableStreamByTaskId(taskId: taskId))
          .stream;

  /// Stores lazily-created [TaskResolver] instances by [taskId].
  ///
  /// Resolvers are reused to coordinate task execution and avoid unnecessary duplication.
  final Map<String, TaskResolver> taskResolvers = {};

  /// Stores expected result types for resolvers, used to detect conflicting type usage.
  ///
  /// Helps enforce consistent return types for tasks sharing the same [taskId].
  final Map<String, Type> resolverTypes = {};

  /// Resets all internal resolver and stream mappings.
  ///
  /// Closes active per-task streams and clears resolver registrations.
  /// Typically used in testing environments or when performing system-wide cleanup.
  void resetManager() {
    taskStreamsByTaskId
      ..forEach((k, v) => v.close())
      ..clear();
    taskResolvers.clear();
    resolverTypes.clear();
  }

  /// Returns the existing [TaskResolver] associated with a [taskId] or [managerId], or creates one using [factory].
  ///
  /// Ensures that multiple requests for the same identifier share a single resolver
  /// instance. Also validates that the resolver always resolves values of the same expected type.
  ///
  /// Throws [MismatchTasksReturnsException] when different type expectations are detected.
  TaskResolver<T> getResolver<T>({
    String? taskId,
    String? managerId,
    required TaskResolver<T> Function() factory,
  }) {
    assert(taskId != null || managerId != null,
        'Either taskId or managerId must be provided.');

    final identifier = taskId ?? managerId!;

    TaskResolver resolver = taskResolvers[identifier] ??= factory();
    if (resolver is TaskResolver<T>) {
      taskId != null
          ? getObservableStreamByTaskId(taskId: taskId)
          : getObservableStreamByManagerId(managerId: managerId);
      return resolver;
    }
    Type typeB = resolverTypes[identifier]!;
    throw MismatchTasksReturnsException(
      taskId: identifier,
      typeA: T,
      typeB: typeB,
    );
  }
}
