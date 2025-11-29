import '../../awesome_task_manager.dart';
import 'awesome_task_manager_impl.dart';

/// The main entry point and abstract interface for the Awesome Task Manager library.
///
/// This class exposes factory creation for different task management strategies,
/// allowing fine-grained control over concurrency behavior. It also provides
/// centralized log event handling and real-time task status monitoring.
///
/// Typically, applications call [AwesomeTaskManager()] once at startup to obtain a
/// shared instance and reuse it across the application lifecycle.
abstract class AwesomeTaskManager {
  static AwesomeTaskManager? _instance;

  /// Creates or returns the existing singleton instance of [AwesomeTaskManager].
  ///
  /// The [mockedInstance] parameter is designed exclusively for test environments.
  /// Providing a mocked instance allows controlled behavior and isolation during tests.
  /// In normal usage, do not pass this parameter.
  factory AwesomeTaskManager({AwesomeTaskManager? mockedInstance}) =>
      _instance ??= mockedInstance ?? AwesomeTaskManagerImpl();

  /// Streams live [TaskStatus] updates for tasks filtered by [taskId].
  ///
  /// Returns:
  /// * A task-specific stream when a [taskId] is provided.
  /// * A global stream with updates from all tasks when [taskId] is `null`.
  ///
  /// Useful for UI bindings, dashboards, or task monitoring components.
  Stream<TaskStatus?> getTaskStatusStream({String? taskId, String? managerId});

  /// Creates a [SharedResultManager] that executes a task only once per [taskId],
  /// sharing the same result among all concurrent callers while preventing duplication.
  ///
  /// Ideal for network requests such as configuration loading or authentication.
  SharedResultManager createSharedResultManager({required String managerId});

  /// Creates a [SequentialQueueManager] that guarantees tasks with the same [taskId]
  /// are executed in strict order, one after another.
  ///
  /// Useful for workflows that require predictable sequencing or state transitions.
  SequentialQueueManager createSequentialQueueManager(
      {required String managerId});

  /// Creates a [TaskPoolManager] which manages a pool of concurrently running tasks,
  /// limiting execution to [poolSize] simultaneous tasks within the manager.
  ///
  /// Useful for batch processing or preventing resource overuse.
  TaskPoolManager createTaskPoolManager(
      {required String managerId, int poolSize = 2});

  /// Creates a [RejectedAfterThresholdManager] that rejects new tasks once
  /// [taskThreshold] concurrent executions are already active.
  ///
  /// Useful when strict concurrency control or operational safety caps are required.
  RejectedAfterThresholdManager createRejectedAfterThresholdManager(
      {required String managerId, int taskThreshold = 1});

  /// Creates a [CancelPreviousTaskManager] that automatically cancels the currently
  /// running task when a newer request with the same [taskId] arrives.
  ///
  /// Useful for rapid-refresh operations such as search suggestions or live polling.
  CancelPreviousTaskManager createCancelPreviousTaskManager(
      {required String managerId, int maximumParallelTasks = 1});

  /// Registers a [LogListener] to receive internal log messages.
  ///
  /// If multiple listeners are registered, all will receive the same event stream.
  /// Listeners should process logs safely without throwing exceptions.
  void registerLogListener(LogListener listener);

  /// Unregisters a previously registered [LogListener].
  ///
  /// Removing a listener stops log event delivery to that consumer.
  void unregisterLogListener(LogListener listener);

  /// Emits a log message to registered listeners or falls back to `developer.log`.
  ///
  /// Parameters mirror the behavior of `dart:developer`:
  /// [message] — Main message to be logged.
  /// [time] — Optional explicit timestamp.
  /// [sequenceNumber] — Event ordering metadata.
  /// [level] — Logging severity level following `dart:developer` conventions.
  /// [name] — Logical source identifier/category for log grouping.
  /// [error] — Optional associated error data.
  /// [stackTrace] — Optional stack trace for issue diagnosis.
  void log(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String name = '',
    Object? error,
    StackTrace? stackTrace,
  });
}
