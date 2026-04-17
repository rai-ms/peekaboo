import 'log_types.dart';
import 'peekaboo_config.dart';
import 'peekaboo_store.dart';

/// Public app-facing API. Call these anywhere — controllers, blocs,
/// services — and the lines show up in the overlay under the "APP"
/// filter chip.
///
/// Every method is wrapped so a bad toString() / throwing listener can
/// never surface to the caller.
class Peekaboo {
  const Peekaboo._();

  /// Toggle capture globally. Defaults to `kDebugMode`.
  static set enabled(bool value) => PeekabooStore.instance.isEnabled = value;
  static bool get enabled => PeekabooStore.instance.isEnabled;

  /// Attach a [PeekabooConfig] — control which channels record, filter
  /// entries, or mirror to an external sink (Sentry, Crashlytics…).
  static void configure(PeekabooConfig config) =>
      PeekabooStore.instance.configure(config);

  /// Wipe the buffer (also exposed via the overlay's Clear button).
  static void clear() => PeekabooStore.instance.clear();

  static void d(String title, {String? body}) =>
      _push(LogLevel.debug, title, body);
  static void i(String title, {String? body}) =>
      _push(LogLevel.info, title, body);
  static void w(String title, {String? body}) =>
      _push(LogLevel.warning, title, body);
  static void e(String title, {String? body}) =>
      _push(LogLevel.error, title, body);

  /// Raw entry — set channel / status / duration yourself.
  static void add(LogEntry entry) => PeekabooStore.instance.add(entry);

  static void _push(LogLevel level, String title, String? body) {
    try {
      PeekabooStore.instance.add(LogEntry(
        at: DateTime.now(),
        channel: LogChannel.app,
        level: level,
        title: title,
        body: body,
      ));
    } catch (_) {
      // Store.add already logs its own failures; nothing more to do.
    }
  }
}
