import '../status/task_status.dart';

typedef TaskExecution = Future<void> Function(String tag);
typedef TaskExceptionHandler = void Function(Exception exception);
typedef TaskResult<T> = ({T? result, Exception? exception});

typedef Task<T> = Future<T> Function(TaskStatus status);

typedef LoadingEvent = Future<void> Function(Future futureToWait,
    {void Function()? onCancelRequested});
