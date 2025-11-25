import 'package:awesome_task_manager/src/streams/observable_stream.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ObservableStream Tests', () {
    test('Stream emits added values', () async {
      final stream = ObservableStream<int>(initialValue: 0);
      final List<int?> emittedValues = [];

      stream.stream.listen(emittedValues.add);
      await Future.delayed(Duration.zero);

      stream.add(1);
      stream.add(2);
      stream.add(3);

      await Future.delayed(Duration.zero); // Allow event loop to run

      expect(emittedValues, equals([0, 1, 2, 3]));
    });

    test('Stream correctly handles errors', () async {
      final stream = ObservableStream<int>(initialValue: 0);
      final List<Object> emittedErrors = [];

      stream.stream.listen(null, onError: emittedErrors.add);
      await Future.delayed(Duration.zero);

      stream.addError(Exception('Test Error'));

      await Future.delayed(Duration.zero); // Allow event loop to run

      expect(emittedErrors.length, 1);
      expect(emittedErrors.first, isException);
    });

    test('Listener count is managed correctly', () async {
      var zeroListenersCalled = false;
      final stream = ObservableStream<int>(
          initialValue: 0, onZeroListeners: () => zeroListenersCalled = true);

      final subscription = stream.stream.listen((_) {});
      await Future.delayed(Duration.zero);

      expect(stream.listenerCount, 1);
      await subscription.cancel();
      expect(stream.listenerCount, 0);
      expect(zeroListenersCalled, isTrue);
    });

    test('Stream yields initial value if provided', () async {
      final stream = ObservableStream<int>(initialValue: 42);
      final List<int?> emittedValues = [];

      stream.stream.listen(emittedValues.add);

      await Future.delayed(Duration.zero); // Allow event loop to run

      expect(emittedValues, equals([42]));
    });

    test('Stream closure is handled correctly', () async {
      final stream = ObservableStream<int>(initialValue: 0);

      await stream.close();
      expect(stream.isClosed, isTrue);
    });
  });
}
