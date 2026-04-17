import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'log_types.dart';
import 'peekaboo_store.dart';

/// Drop-in Dio interceptor that pushes every request/response/error
/// into the overlay. Attach alongside any console logger — both can
/// coexist.
///
/// ```dart
/// dio.interceptors.add(PeekabooDioInterceptor());
/// ```
///
/// Every callback is wrapped in try/catch so a JSON encode or a stream
/// emit failure can never interrupt the real request pipeline.
class PeekabooDioInterceptor extends Interceptor {
  PeekabooDioInterceptor();

  final JsonEncoder _encoder = const JsonEncoder.withIndent('  ');
  static const _startTimeKey = 'peekaboo.startTime';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    try {
      options.extra[_startTimeKey] = DateTime.now();
    } catch (e, st) {
      _fail('onRequest', e, st);
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    try {
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
    } catch (e, st) {
      _fail('onResponse', e, st);
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
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
    } catch (e, st) {
      _fail('onError', e, st);
    }
    super.onError(err, handler);
  }

  Duration? _elapsed(RequestOptions options) {
    try {
      final started = options.extra[_startTimeKey];
      if (started is DateTime) return DateTime.now().difference(started);
    } catch (_) {}
    return null;
  }

  String? _safeEncode(Object? data) {
    if (data == null) return null;
    try {
      return _encoder.convert(data);
    } catch (_) {
      try {
        return data.toString();
      } catch (_) {
        return '<unencodable>';
      }
    }
  }

  void _fail(String what, Object err, StackTrace st) {
    if (kDebugMode) {
      debugPrint('[peekaboo] dio $what failed: $err\n$st');
    }
  }
}
