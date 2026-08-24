import 'dart:async';

/// Что именно произошло в сетевом слое.
enum NetworkEventKind { request, response, failure, refreshStarted, refreshDone, retry }

/// Событие цепочки интерсепторов — то, что обычно видно только в логе.
class NetworkEvent {
  NetworkEvent({
    required this.kind,
    required this.message,
    required this.at,
    this.statusCode,
    this.duration,
  });

  final NetworkEventKind kind;
  final String message;
  final DateTime at;
  final int? statusCode;
  final Duration? duration;
}

/// Шина событий сетевого слоя: интерсепторы пишут, экран демо читает.
///
/// `broadcast` — слушателей может не быть вовсе, а может быть несколько.
class NetworkEventBus {
  final StreamController<NetworkEvent> _controller =
      StreamController<NetworkEvent>.broadcast();

  final List<NetworkEvent> _history = <NetworkEvent>[];

  Stream<NetworkEvent> get events => _controller.stream;

  List<NetworkEvent> get history => List<NetworkEvent>.unmodifiable(_history);

  void add(NetworkEvent event) {
    _history.insert(0, event);
    if (_history.length > 60) {
      _history.removeLast();
    }

    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void clear() => _history.clear();

  Future<void> dispose() => _controller.close();
}
