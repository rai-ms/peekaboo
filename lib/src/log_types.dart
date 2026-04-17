import 'package:flutter/foundation.dart';

/// Which stream produced the entry — drives filter chips + colour in the
/// overlay. Using an enum (not raw strings) keeps call sites type-safe.
enum LogChannel {
  api('API'),
  socket('SOCKET'),
  app('APP');

  final String label;
  const LogChannel(this.label);
}

/// Severity. API 4xx responses and Dio errors map to [error]; everything
/// else defaults to [info] / [debug].
enum LogLevel {
  debug,
  info,
  warning,
  error;

  bool get isError => this == LogLevel.error;
  bool get isWarning => this == LogLevel.warning;
}

/// One line in the overlay. `body` is pretty-printed on demand; we keep
/// it as a [String] so widgets don't re-encode JSON on every rebuild.
@immutable
class LogEntry {
  final DateTime at;
  final LogChannel channel;
  final LogLevel level;
  final String title;
  final String? body;
  final int? statusCode;
  final Duration? duration;

  const LogEntry({
    required this.at,
    required this.channel,
    required this.level,
    required this.title,
    this.body,
    this.statusCode,
    this.duration,
  });

  String get timeText =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}:'
      '${at.second.toString().padLeft(2, '0')}.'
      '${at.millisecond.toString().padLeft(3, '0')}';

  String get statusText => statusCode == null ? '' : '$statusCode';
  String get durationText =>
      duration == null ? '' : '${duration!.inMilliseconds}ms';
}
