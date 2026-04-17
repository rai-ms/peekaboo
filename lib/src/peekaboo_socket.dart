import 'log_types.dart';
import 'peekaboo_store.dart';

/// Socket.IO helper — since socket_io_client isn't a hard dependency of
/// this package (we don't want to pin the app's version), the consumer
/// manually forwards every emit + incoming event to these helpers.
///
/// ```dart
/// socket.onAny((event, data) => PeekabooSocket.incoming(event, data));
/// // before emit:
/// PeekabooSocket.outgoing(eventName, payload);
/// socket.emit(eventName, payload);
/// ```
class PeekabooSocket {
  const PeekabooSocket._();

  static void outgoing(String event, [Object? data]) =>
      _push('→ $event', data);
  static void incoming(String event, [Object? data]) =>
      _push('← $event', data);
  static void error(String event, Object err) {
    PeekabooStore.instance.add(LogEntry(
      at: DateTime.now(),
      channel: LogChannel.socket,
      level: LogLevel.error,
      title: '✗ $event',
      body: err.toString(),
    ));
  }

  static void _push(String title, Object? data) {
    PeekabooStore.instance.add(LogEntry(
      at: DateTime.now(),
      channel: LogChannel.socket,
      level: LogLevel.debug,
      title: title,
      body: data?.toString(),
    ));
  }
}
