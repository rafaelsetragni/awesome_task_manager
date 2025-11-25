import '../status/task_status.dart';

/// Represents a generic asynchronous execution callback used for fire-and-forget task operations.
///
/// The [tag] parameter provides a contextual identifier supplied by the caller.
typedef TaskExecution = Future<void> Function(String tag);

/// Defines a callback invoked when a task throws an exception.
///
/// Allows centralized error handling and custom recovery logic.
typedef TaskExceptionHandler = void Function(Exception exception);

/// Structured tuple returned after a task completes.
///
/// Contains either a [result] of type [T] on success, or an [exception] when execution fails.
/// Only one of these fields is expected to be non-null at a time.
typedef TaskResult<T> = ({T? result, Exception? exception});

/// Represents an asynchronous unit of work that receives a read-only [TaskStatus]
/// snapshot for context and returns a result of type [T].
///
/// This signature is used by all execution resolvers in the task management framework.
typedef Task<T> = Future<T> Function(TaskStatus status);

/// Defines a loading event wrapper that waits for a given [futureToWait] while optionally
/// providing an [onCancelRequested] callback.
///
/// Commonly used to integrate async progress handling with UI loading indicators.
typedef LoadingEvent = Future<void> Function(Future futureToWait,
    {void Function()? onCancelRequested});
