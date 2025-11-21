import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:flutter/cupertino.dart';

class AwesomeTaskObserver<T> extends StatelessWidget {
  final String? taskId;
  final AsyncWidgetBuilder<TaskStatus> builder;

  const AwesomeTaskObserver({required this.builder, super.key, this.taskId});

  @override
  Widget build(BuildContext context) => StreamBuilder<TaskStatus>(
        stream: AwesomeTaskManager().getTaskStatusStream(taskId: taskId),
        builder: (context, snapshot) {
          AwesomeTaskManager()
              .log('AwesomeTaskObserver rebuilt for taskId: $taskId');
          return builder(context, snapshot);
        },
      );
}
