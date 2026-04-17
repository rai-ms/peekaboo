/// Peekaboo — a draggable in-app log overlay for Flutter.
///
/// Capture Dio HTTP traffic, Socket.IO events, and internal app logs
/// and surface them through a floating eye that sits on top of any
/// screen. Debug-only by default.
///
/// ```dart
/// import 'package:peekaboo/peekaboo.dart';
///
/// // 1. Wrap the app root
/// MaterialApp(
///   builder: (ctx, child) => PeekabooOverlay(
///     theme: PeekabooTheme.defaults.copyWith(panelAccent: Colors.pink),
///     child: child ?? const SizedBox(),
///   ),
/// );
///
/// // 2. Plug into Dio
/// dio.interceptors.add(PeekabooDioInterceptor());
///
/// // 3. Forward socket events
/// socket.onAny((event, data) => PeekabooSocket.incoming(event, data));
///
/// // 4. Log from app code
/// Peekaboo.d('Loading feed');
/// Peekaboo.e('Login failed', body: err.toString());
///
/// // Optional: per-channel toggle + remote sink
/// Peekaboo.configure(PeekabooConfig(
///   enabledChannels: {LogChannel.api, LogChannel.app},
///   onCapture: (e) { if (e.level.isError) Sentry.captureMessage(e.title); },
/// ));
/// ```
library peekaboo;

export 'src/log_types.dart';
export 'src/peekaboo_api.dart';
export 'src/peekaboo_config.dart';
export 'src/peekaboo_dio_interceptor.dart';
export 'src/peekaboo_overlay.dart';
export 'src/peekaboo_socket.dart';
export 'src/peekaboo_store.dart';
export 'src/peekaboo_theme.dart';
