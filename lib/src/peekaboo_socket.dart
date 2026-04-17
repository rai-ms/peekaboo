import 'log_types.dart';
import 'peekaboo_store.dart';

/// Socket.IO helper — since `socket_io_client` isn't a hard dependency
/// of this package, the consumer forwards every emit + incoming event
/// to these helpers.
///
/// ```dart
/// socket.onAny((event, data) => PeekabooSocket.incoming(event, data));
/// PeekabooSocket.outgoing(eventName, payload);
/// socket.emit(eventName, payload);
/// ```
///
/// Every helper is wrapped in try/catch so a socket plugin throwing
/// during toString cannot take down the host app.
class PeekabooSocket {
  const PeekabooSocket._();

  static void outgoing(String event, [Object? data]) =>
      _push('→ $event', data, LogLevel.debug);

  static void incoming(String event, [Object? data]) =>
      _push('← $event', data, LogLevel.debug);

  static void error(String event, Object err) {
    try {
      PeekabooStore.instance.add(LogEntry(
        at: DateTime.now(),
        channel: LogChannel.socket,
        level: LogLevel.error,
        title: '✗ $event',
        body: err.toString(),
      ));
    } catch (_) {}
  }

  static void _push(String title, Object? data, LogLevel level) {
    try {
      PeekabooStore.instance.add(LogEntry(
        at: DateTime.now(),
        channel: LogChannel.socket,
        level: level,
        title: title,
        body: data?.toString(),
      ));
    } catch (_) {}
  }
}
