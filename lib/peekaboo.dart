/// Peekaboo — a draggable in-app log overlay for Flutter.
///
/// ```dart
/// import 'package:peekaboo/peekaboo.dart';
///
/// MaterialApp(
///   builder: (ctx, child) => PeekabooOverlay(
///     theme: PeekabooTheme.defaults.copyWith(panelAccent: Colors.pink),
///     child: child ?? const SizedBox(),
///   ),
/// );
///
/// dio.interceptors.add(PeekabooDioInterceptor());
/// socket.onAny((e, d) => PeekabooSocket.incoming(e, d));
/// Peekaboo.i('User tapped retry');
/// ```
library peekaboo;

export 'src/log_types.dart';
export 'src/peekaboo_api.dart';
export 'src/peekaboo_dio_interceptor.dart';
export 'src/peekaboo_overlay.dart';
export 'src/peekaboo_socket.dart';
export 'src/peekaboo_store.dart';
export 'src/peekaboo_theme.dart';
