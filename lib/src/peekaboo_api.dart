import 'log_types.dart';
import 'peekaboo_store.dart';

/// Public app-facing API. Call these anywhere in your app (controllers,
/// blocs, services) and the lines show up alongside the captured API
/// and socket traffic in the overlay's "APP" filter chip.
///
/// Example:
/// ```dart
/// Peekaboo.d('Refreshing feed');
/// Peekaboo.w('Unexpected empty list');
/// Peekaboo.e('Login failed', body: error.toString());
/// ```
class Peekaboo {
  const Peekaboo._();

  /// Toggle capture globally. Defaults to `kDebugMode`.
  static set enabled(bool value) => PeekabooStore.instance.isEnabled = value;
  static bool get enabled => PeekabooStore.instance.isEnabled;

  /// Wipe the buffer (used by the Clear button in the overlay).
  static void clear() => PeekabooStore.instance.clear();

  static void d(String title, {String? body}) =>
      _push(LogLevel.debug, title, body);
  static void i(String title, {String? body}) =>
      _push(LogLevel.info, title, body);
  static void w(String title, {String? body}) =>
      _push(LogLevel.warning, title, body);
  static void e(String title, {String? body}) =>
      _push(LogLevel.error, title, body);

  /// Raw entry — for producers that want to set channel/status/duration
  /// directly (e.g. Dio interceptor, socket wrapper).
  static void add(LogEntry entry) => PeekabooStore.instance.add(entry);

  static void _push(LogLevel level, String title, String? body) {
    PeekabooStore.instance.add(LogEntry(
      at: DateTime.now(),
      channel: LogChannel.app,
      level: level,
      title: title,
      body: body,
    ));
  }
}
