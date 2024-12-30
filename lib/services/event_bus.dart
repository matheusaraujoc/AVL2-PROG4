import 'dart:async';

class SpaceEventBus {
  static final _instance = SpaceEventBus._internal();
  factory SpaceEventBus() => _instance;
  SpaceEventBus._internal();

  final _controller = StreamController<void>.broadcast();
  Stream<void> get stream => _controller.stream;
  void notify() => _controller.add(null);

  void dispose() {}
}
