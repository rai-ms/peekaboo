import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'log_types.dart';
import 'peekaboo_config.dart';

/// Ring-buffered log store + broadcast stream. Producers (Dio
/// interceptor, socket helper, `Peekaboo.*` api) push entries via [add].
///
/// All work is wrapped in try/catch — a bad sink, a circular JSON, or a
/// listener that throws cannot bring down the host app. Peekaboo
/// failures print to debugPrint in debug builds and disappear in
/// release.
class PeekabooStore {
  PeekabooStore._();
  static final PeekabooStore instance = PeekabooStore._();

  static const int _maxEntries = 500;

  final List<LogEntry> _buffer = [];
  final StreamController<List<LogEntry>> _controller =
      StreamController<List<LogEntry>>.broadcast();

  bool isEnabled = kDebugMode;
  PeekabooConfig _config = PeekabooConfig.defaults;
  bool _emitScheduled = false;

  Stream<List<LogEntry>> get stream => _controller.stream;
  List<LogEntry> get entries => List.unmodifiable(_buffer);
  PeekabooConfig get config => _config;

  /// Attach a custom configuration. Call at app boot or behind a
  /// feature flag. Replaces any previously-set config.
  void configure(PeekabooConfig config) {
    _config = config;
  }

  /// Buffer + broadcast one entry. Silently drops when disabled, when
  /// the channel isn't in [PeekabooConfig.enabledChannels], or when a
  /// user-supplied filter returns false. Never throws.
  void add(LogEntry entry) {
    try {
      if (!isEnabled) return;
      if (!_config.enabledChannels.contains(entry.channel)) return;
      final filter = _config.filter;
      if (filter != null && !filter(entry)) return;

      _buffer.insert(0, entry);
      if (_buffer.length > _maxEntries) {
        _buffer.removeRange(_maxEntries, _buffer.length);
      }
      // Coalesce emits to ≤ 1 per animation frame. Without this the
      // overlay rebuilds dozens of times per second on a noisy socket,
      // which tears down the InkWell gesture recognisers mid-tap and
      // kills the row-tap interaction. One frame-scheduled emit keeps
      // the UI live without losing taps.
      _scheduleEmit();
      final sink = _config.onCapture;
      if (sink != null) {
        try {
          sink(entry);
        } catch (e, st) {
          _fail('onCapture sink', e, st);
        }
      }
    } catch (e, st) {
      _fail('add entry', e, st);
    }
  }

  void clear() {
    try {
      _buffer.clear();
      _controller.add(const []);
    } catch (e, st) {
      _fail('clear', e, st);
    }
  }

  /// Schedule a single broadcast after the current frame. Subsequent
  /// `add` calls within the same frame coalesce into one emit.
  void _scheduleEmit() {
    if (_emitScheduled) return;
    _emitScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _emitScheduled = false;
      try {
        _controller.add(List.unmodifiable(_buffer));
      } catch (e, st) {
        _fail('stream broadcast', e, st);
      }
    });
  }

  void _fail(String what, Object err, StackTrace st) {
    if (kDebugMode) {
      debugPrint('[peekaboo] $what failed: $err\n$st');
    }
  }
}
