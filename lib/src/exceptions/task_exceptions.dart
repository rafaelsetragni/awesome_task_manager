abstract class AwesomeTaskException implements Exception {}

class TooManyTasksException implements AwesomeTaskException {
  final String taskId;

  TooManyTasksException(this.taskId);

  @override
  String toString() =>
      'TooManyTasksException: Too many tasks in execution for $taskId';
}

class InvalidTasksParameterException implements AwesomeTaskException {
  final String parameterName;
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

class MismatchTasksReturnsException implements AwesomeTaskException {
  final String taskId;
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

class TimeoutException implements Exception {
  final String taskId;

  TimeoutException({required this.taskId});

  @override
  String toString() => 'TimeoutException: The task $taskId has timed out.';
}

class CancellationException implements Exception {
  final String taskId;

  CancellationException({required this.taskId});

  @override
  String toString() => 'CancellationException: The task $taskId was cancelled.';
}