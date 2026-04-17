import 'dart:async';

import 'package:flutter/foundation.dart';

import 'log_types.dart';

/// Ring-buffered log store + broadcast stream. The overlay subscribes to
/// [stream] and re-renders; producers (Dio interceptor, socket wrapper,
/// internal `Peekaboo.log*` helpers) push [LogEntry]s via [add].
///
/// Defaults to debug-only — flip [isEnabled] for QA release builds.
class PeekabooStore {
  PeekabooStore._();
  static final PeekabooStore instance = PeekabooStore._();

  static const int _maxEntries = 500;

  final List<LogEntry> _buffer = [];
  final StreamController<List<LogEntry>> _controller =
      StreamController<List<LogEntry>>.broadcast();

  bool isEnabled = kDebugMode;

  Stream<List<LogEntry>> get stream => _controller.stream;
  List<LogEntry> get entries => List.unmodifiable(_buffer);

  void add(LogEntry entry) {
    if (!isEnabled) return;
    _buffer.insert(0, entry);
    if (_buffer.length > _maxEntries) {
      _buffer.removeRange(_maxEntries, _buffer.length);
    }
    _controller.add(List.unmodifiable(_buffer));
  }

  void clear() {
    _buffer.clear();
    _controller.add(const []);
  }
}
