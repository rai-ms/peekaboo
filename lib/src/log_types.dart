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

/// Extra fields attached to every API-channel entry. Keep these out of
/// the base [LogEntry] so socket/app entries don't pay the field cost.
@immutable
class ApiDetails {
  final String? method;
  final String? url; // full URL including scheme + host
  final Map<String, String> requestHeaders;
  final String? requestBody; // pretty-printed JSON if parseable
  final Map<String, String> responseHeaders;

  const ApiDetails({
    this.method,
    this.url,
    this.requestHeaders = const {},
    this.requestBody,
    this.responseHeaders = const {},
  });

  /// Render the request as a copy-paste `curl` command.
  String asCurl() {
    final buf = StringBuffer('curl -X ${method ?? 'GET'} ');
    requestHeaders.forEach((k, v) {
      if (k.toLowerCase() == 'cookie') return;
      buf.write('\\\n  -H ${_sh("$k: $v")} ');
    });
    if (requestBody != null && requestBody!.isNotEmpty) {
      buf.write('\\\n  -d ${_sh(requestBody!)} ');
    }
    buf.write('\\\n  ${_sh(url ?? '')}');
    return buf.toString();
  }

  static String _sh(String s) => "'${s.replaceAll("'", "'\\''")}'";
}

/// One line in the overlay. `body` is pretty-printed on demand; we keep
/// it as a [String] so widgets don't re-encode JSON on every rebuild.
@immutable
class LogEntry {
  final DateTime at;
  final LogChannel channel;
  final LogLevel level;
  final String title;
  final String? body; // response body (API), event payload (socket), freeform (app)
  final int? statusCode;
  final Duration? duration;
  final ApiDetails? api; // only populated on LogChannel.api entries

  const LogEntry({
    required this.at,
    required this.channel,
    required this.level,
    required this.title,
    this.body,
    this.statusCode,
    this.duration,
    this.api,
  });

  String get timeText =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}:'
      '${at.second.toString().padLeft(2, '0')}.'
      '${at.millisecond.toString().padLeft(3, '0')}';

  String get statusText => statusCode == null ? '' : '$statusCode';
  String get durationText =>
      duration == null ? '' : '${duration!.inMilliseconds}ms';

  /// One-shot summary for clipboard "copy all" — includes everything
  /// a developer would want to attach to a bug report.
  String asShareText() {
    final buf = StringBuffer()
      ..writeln('[${channel.label}] $title')
      ..writeln('at    : $timeText');
    if (statusCode != null) buf.writeln('status: $statusCode');
    if (duration != null) buf.writeln('took  : ${duration!.inMilliseconds}ms');
    if (api?.url != null) buf.writeln('url   : ${api!.url}');
    if (api?.requestHeaders.isNotEmpty ?? false) {
      buf.writeln('');
      buf.writeln('--- request headers ---');
      api!.requestHeaders.forEach((k, v) => buf.writeln('$k: $v'));
    }
    if (api?.requestBody != null) {
      buf.writeln('');
      buf.writeln('--- request body ---');
      buf.writeln(api!.requestBody);
    }
    if (body != null) {
      buf.writeln('');
      buf.writeln('--- response ---');
      buf.writeln(body);
    }
    return buf.toString();
  }
}
