import 'dart:convert';

import 'package:dio/dio.dart';

import 'log_types.dart';
import 'peekaboo_store.dart';

/// Drop-in Dio interceptor that pushes every request/response/error into
/// the overlay. Attach alongside any console logger — both can coexist.
///
/// ```dart
/// dio.interceptors.add(PeekabooDioInterceptor());
/// ```
class PeekabooDioInterceptor extends Interceptor {
  PeekabooDioInterceptor();

  final JsonEncoder _encoder = const JsonEncoder.withIndent('  ');
  static const _startTimeKey = 'peekaboo.startTime';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.extra[_startTimeKey] = DateTime.now();
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final opts = response.requestOptions;
    final status = response.statusCode ?? 0;
    final level = status >= 400 ? LogLevel.error : LogLevel.info;
    PeekabooStore.instance.add(LogEntry(
      at: DateTime.now(),
      channel: LogChannel.api,
      level: level,
      title: '${opts.method} ${opts.uri.path}',
      body: _safeEncode(response.data),
      statusCode: status,
      duration: _elapsed(opts),
    ));
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final opts = err.requestOptions;
    PeekabooStore.instance.add(LogEntry(
      at: DateTime.now(),
      channel: LogChannel.api,
      level: LogLevel.error,
      title: '${opts.method} ${opts.uri.path} — ${err.type.name}',
      body: _safeEncode(err.response?.data) ?? err.message,
      statusCode: err.response?.statusCode,
      duration: _elapsed(opts),
    ));
    super.onError(err, handler);
  }

  Duration? _elapsed(RequestOptions options) {
    final started = options.extra[_startTimeKey];
    if (started is DateTime) return DateTime.now().difference(started);
    return null;
  }

  String? _safeEncode(Object? data) {
    if (data == null) return null;
    try {
      return _encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
