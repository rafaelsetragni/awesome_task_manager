/// Base interface for all exceptions thrown by the Awesome Task Manager.
///
/// Implementations of this exception represent specific error conditions
/// that can occur while creating, executing or monitoring tasks.
abstract class AwesomeTaskException implements Exception {}

/// Thrown when too many tasks are simultaneously running with the same taskId.
///
/// Typically this indicates that the caller attempted to start a task that
/// is already executing beyond the allowed concurrency limit.
class TooManyTasksException implements AwesomeTaskException {
  /// Identifier of the task that triggered the concurrency violation.
  final String taskId;

  TooManyTasksException(this.taskId);

  /// Returns a descriptive error message for debugging purposes.
  @override
  String toString() =>
      'TooManyTasksException: Too many tasks in execution for $taskId';
}

/// Thrown when a task receives an invalid or unsupported parameter value.
///
/// This may indicate incorrect caller usage or malformed input data.
class InvalidTasksParameterException implements AwesomeTaskException {
  /// Name of the parameter that contains the invalid value.
  final String parameterName;

  /// The actual value received that caused the validation failure.
  final dynamic value;

  InvalidTasksParameterException({
    required this.parameterName,
    required this.value,
  });

  @override
  String toString() =>
      'InvalidTasksParameterException: Parameter value of $parameterName is '
      'invalid ($value)';
}

/// Thrown when tasks sharing the same taskId attempt to return incompatible types.
///
/// A task must always return values of the same expected type across executions.
class MismatchTasksReturnsException implements AwesomeTaskException {
  /// Identifier of the task whose return types are conflicting.
  final String taskId;

  /// The mismatching expected types detected for the conflicting tasks.
  final Type? typeA, typeB;

  MismatchTasksReturnsException({
    required this.taskId,
    required this.typeA,
    required this.typeB,
  });

  @override
  String toString() =>
      'MismatchTasksReturnsException: Tasks with same ID $taskId are requesting'
      ' different return types'
      ' (A return: $typeA, B return: $typeB)';
}

/// Thrown when a task exceeds its allowed execution duration.
///
/// Typically triggered by network delays, infinite loops, or deadlocks.
class TimeoutException implements Exception {
  /// Identifier of the task that reached timeout.
  final String taskId;

  TimeoutException({required this.taskId});

  @override
  String toString() => 'TimeoutException: The task $taskId has timed out.';
}

/// Thrown when a task is intentionally cancelled before it completes.
///
/// This can occur due to user action or system-controlled cancellation logic.
class CancellationException implements Exception {
  /// Identifier of the task that was cancelled.
  final String taskId;

  CancellationException({required this.taskId});

  @override
  String toString() => 'CancellationException: The task $taskId was cancelled.';
}
