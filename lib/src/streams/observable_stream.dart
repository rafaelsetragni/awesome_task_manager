import 'dart:async';

class ObservableStream<T> {
  final _controller = StreamController<T>.broadcast();
  T? _currentValue;
  int _listenerCount = 0;
  final void Function()? onZeroListeners;

  ObservableStream({T? initialValue, this.onZeroListeners})
      : _currentValue = initialValue;

  void _incrementListenerCount() {
    _listenerCount++;
  }

  void _decrementListenerCount() {
    _listenerCount--;
    if (_listenerCount == 0) {
      onZeroListeners?.call();
    }
  }

  int get listenerCount => _listenerCount;

  T? get valueOrNull => _currentValue;

  void add(T value) {
    _currentValue = value;
    _controller.add(value);
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  Stream<T?> get stream async* {
    _incrementListenerCount();
    yield _currentValue;

    try {
      // Yield all events from the controller's stream
      yield* _controller.stream;
    } finally {
      _decrementListenerCount();
    }
  }

  Future<void> close() => _controller.close();

  bool get isClosed => _controller.isClosed;
}
