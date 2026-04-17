import 'log_types.dart';

/// Host-app configuration for what Peekaboo records + what it does with
/// captured entries.
///
/// Attach via [PeekabooStore.instance.configure] at app boot:
///
/// ```dart
/// PeekabooStore.instance.configure(PeekabooConfig(
///   enabledChannels: {LogChannel.api, LogChannel.app},   // silence socket
///   filter: (e) => !e.title.contains('/heartbeat'),      // drop noise
///   onCapture: (e) {                                     // forward to Sentry
///     if (e.level.isError) Sentry.captureMessage(e.title, extra: e.body);
///   },
/// ));
/// ```
///
/// Any field can be omitted — the default accepts every channel, every
/// entry, and forwards nothing.
class PeekabooConfig {
  /// Channels that are actually recorded. Anything outside this set is
  /// silently dropped before it hits the buffer. Defaults to all three.
  final Set<LogChannel> enabledChannels;

  /// Return `false` to skip an entry (neither buffered nor forwarded).
  /// Use for per-URL muting, secret-token scrubbing, etc.
  final bool Function(LogEntry entry)? filter;

  /// Fires for every accepted entry *after* [filter]. Use to mirror logs
  /// into Sentry, Firebase Crashlytics, a file sink, or your own
  /// analytics pipeline. Exceptions here are swallowed so a bad sink
  /// can't crash the app.
  final void Function(LogEntry entry)? onCapture;

  const PeekabooConfig({
    this.enabledChannels = const {
      LogChannel.api,
      LogChannel.socket,
      LogChannel.app,
    },
    this.filter,
    this.onCapture,
  });

  /// Wide-open default — accept every channel, no filtering, no sink.
  static const PeekabooConfig defaults = PeekabooConfig();
}
