# peekaboo 👀

> A draggable in-app log overlay for Flutter — every Dio request, every Socket.IO event, every `Peekaboo.d/i/w/e` line, on a floating eye that sits on top of whatever screen you're debugging. Zero-setup for QA builds; debug-only by default; never crashes the host app.

![flutter](https://img.shields.io/badge/flutter-%E2%89%A53.19-blue) ![license](https://img.shields.io/badge/license-MIT-green)

## Why

- **QA without `flutter run`.** Ship a release APK, tap the eye, see live logs. No ADB, no desktop tether.
- **One overlay, three streams.** HTTP + sockets + your own app lines in the same scrollback, filterable.
- **Fully themable.** Match your brand. Every colour, icon, label, dimension is on `PeekabooTheme`.
- **Crash-safe.** Every producer, sink, and UI path wraps in `try/catch` — a bad JSON encode or listener cannot take the host app down.
- **Tiny footprint.** Pure Dart, one soft dependency (`dio`). 500-entry ring buffer.

## Install

Not on pub.dev yet — pull via git:

```yaml
dependencies:
  peekaboo:
    git:
      url: https://github.com/rai-ms/peekaboo
      ref: main
```

```bash
flutter pub get
```

## Quick start — four steps

### 1 · Wrap your app root

```dart
import 'package:peekaboo/peekaboo.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      builder: (context, child) => PeekabooOverlay(
        child: child ?? const SizedBox(),
      ),
    );
  }
}
```

Chaining with other `builder`s (BotToast, EasyLoading, …) — Peekaboo should wrap **last** so its panel renders above everything else:

```dart
builder: (ctx, child) {
  final inner = BotToastInit()(ctx, child);
  return PeekabooOverlay(child: inner);
}
```

### 2 · Plug into Dio

```dart
final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
dio.interceptors.add(PeekabooDioInterceptor());
```

Every request now shows method + path + status + elapsed ms, tappable for the full pretty-printed JSON body.

### 3 · Forward socket traffic

`socket_io_client` isn't a hard dependency — you forward events yourself:

```dart
final socket = io.io(url, options);

// Incoming
socket.onAny((event, data) => PeekabooSocket.incoming(event, data));

// Outgoing — wrap your existing emit helper
void emit(String event, Object? data) {
  PeekabooSocket.outgoing(event, data);
  socket.emit(event, data);
}

// Errors
socket.onConnectError((err) => PeekabooSocket.error('connect_error', err));
```

### 4 · Log from anywhere

```dart
Peekaboo.d('Refreshing feed…');
Peekaboo.i('User tapped retry');
Peekaboo.w('Empty response, falling back to cache');
Peekaboo.e('Login failed', body: err.toString());
```

## Using the overlay

| Gesture | What it does |
|---|---|
| **Tap** the eye | Open the log panel |
| **Long-press** the eye | Clear the buffer |
| **Drag** the eye | Move anywhere on screen |
| Tap a row | Full detail sheet with copy button |
| Tap a filter chip | Toggle channel visibility (API / SOCKET / APP) |
| Type in the search box | Live-filter by title or body |

The eye flashes red + shows a badge when the buffer has any errors.

## Theming

Every visual is on `PeekabooTheme`. Pass a custom instance:

```dart
PeekabooOverlay(
  theme: PeekabooTheme.defaults.copyWith(
    // Floating eye
    floatingButtonColor: const Color(0xFF7B1F70),
    floatingButtonErrorColor: const Color(0xFFEC135B),
    floatingButtonIconColor: Colors.white,
    floatingButtonSize: 56,
    floatingButtonIcon: Icons.bug_report,

    // Panel shell
    panelBackground: const Color(0xFF0F0B1A),
    panelAccent: const Color(0xFFEC135B),
    panelTextMuted: const Color(0xFF94A3B8),

    // Filter chip
    chipBackgroundSelected: const Color(0xFFEC135B),

    // Severity tints
    levelInfoColor: const Color(0xFF10B981),
    levelErrorColor: const Color(0xFFEF4444),

    // i18n — keys: title, clear, search, empty
    labels: const {
      'title': 'Ninja Logs',
      'clear': 'Wipe',
      'search': 'Find…',
      'empty': 'Nothing yet',
    },
  ),
  child: child ?? const SizedBox(),
)
```

### Every theme field

| Section | Field | Default |
|---|---|---|
| Floating eye | `floatingButtonColor` | `#111827` |
| | `floatingButtonErrorColor` | `#DC2626` |
| | `floatingButtonIconColor` | white |
| | `floatingButtonSize` | 52 |
| | `floatingButtonIcon` | `Icons.remove_red_eye_outlined` |
| | `floatingButtonShadow` | soft black |
| Panel | `panelBackground` | `#0F172A` |
| | `panelHeaderColor` | `#1E293B` |
| | `panelTextPrimary` | white |
| | `panelTextMuted` | `#94A3B8` |
| | `panelDivider` | `#1E293B` |
| | `panelAccent` | `#EC135B` |
| Severity | `levelDebugColor` | `#64748B` |
| | `levelInfoColor` | `#10B981` |
| | `levelWarningColor` | `#F59E0B` |
| | `levelErrorColor` | `#EF4444` |
| Chip | `chipBackground` | `#1E293B` |
| | `chipBackgroundSelected` | `#EC135B` |
| | `chipText` | `#94A3B8` |
| | `chipTextSelected` | white |
| i18n | `labels` | `{}` → English fallback |

## Configuration — what Peekaboo records

`PeekabooConfig` lets the host app decide which channels get captured, filter individual entries, and optionally mirror every entry into a remote sink (Sentry, Crashlytics, a file, …).

```dart
Peekaboo.configure(PeekabooConfig(
  // Silence the SOCKET channel, keep API + APP
  enabledChannels: {LogChannel.api, LogChannel.app},

  // Drop noisy heartbeat traffic
  filter: (entry) => !entry.title.contains('/heartbeat'),

  // Forward errors to Sentry
  onCapture: (entry) {
    if (entry.level.isError) {
      Sentry.captureMessage(entry.title, level: SentryLevel.error);
    }
  },
));
```

Defaults — every channel on, no filter, no sink — so Peekaboo works out of the box.

## Toggle on / off

Default: debug builds only (`Peekaboo.enabled = kDebugMode`).

Flip it on for a QA release:

```dart
void main() {
  Peekaboo.enabled = true;
  runApp(const MyApp());
}
```

Wire to a hidden gesture if you don't want QA exposing the overlay to end users:

```dart
GestureDetector(
  onTap: () {
    _taps++;
    if (_taps >= 5) {
      Peekaboo.enabled = !Peekaboo.enabled;
      _taps = 0;
    }
  },
  child: Image.asset('assets/logo.png'),
)
```

When disabled, `PeekabooOverlay` returns the child unchanged, every `Peekaboo.*` helper is an early-return, and the Dio/socket producers push nothing. Zero runtime cost.

## Safety — how Peekaboo refuses to crash

Every producer and sink wraps its work in `try/catch`:

- Dio interceptor: request/response/error callbacks — failures don't break the call pipeline.
- Socket helper: all three helpers — a broken `toString()` can't propagate.
- `Peekaboo.d/i/w/e` — buffer + stream failures are swallowed.
- `onCapture` sink — a thrown exception in Sentry/Crashlytics won't ripple back into the app.
- Overlay `StreamBuilder` — a render glitch shows an empty list, never a red screen.

Failures print to `debugPrint` in debug builds and disappear in release.

## Recipes

### Record custom entries

```dart
Peekaboo.add(LogEntry(
  at: DateTime.now(),
  channel: LogChannel.app,
  level: LogLevel.info,
  title: 'flag:new_onboarding = true',
  body: 'userId=42, variant=B',
));
```

### Use with Riverpod / Bloc

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<SignInRequested>((event, emit) async {
      Peekaboo.d('sign-in requested', body: event.email);
      try {
        final user = await repo.signIn(event);
        Peekaboo.i('sign-in ok', body: 'uid=${user.id}');
        emit(AuthReady(user));
      } catch (e, st) {
        Peekaboo.e('sign-in failed', body: '$e\n$st');
        emit(AuthError(e));
      }
    });
  }
}
```

### Scrub sensitive fields before logging

Write a wrapping interceptor that redacts before Peekaboo sees the body:

```dart
class ScrubInterceptor extends Interceptor {
  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    final data = r.data;
    if (data is Map && data['token'] != null) data['token'] = '***';
    super.onResponse(r, h);
  }
}

dio.interceptors.add(ScrubInterceptor());       // runs first
dio.interceptors.add(PeekabooDioInterceptor()); // captures the redacted body
```

Or block via the filter callback:

```dart
Peekaboo.configure(PeekabooConfig(
  filter: (e) => !(e.body?.contains('"password"') ?? false),
));
```

## API summary

| Symbol | Purpose |
|---|---|
| `PeekabooOverlay` | The draggable eye + panel widget |
| `PeekabooTheme` | All visual / label config (`copyWith`-able) |
| `PeekabooConfig` | Enabled channels + filter + sink |
| `PeekabooDioInterceptor` | Drop-in Dio interceptor |
| `PeekabooSocket.outgoing / incoming / error` | Socket.IO helper |
| `Peekaboo.d / i / w / e` | App-level log helpers |
| `Peekaboo.add(LogEntry)` | Raw entry |
| `Peekaboo.configure(PeekabooConfig)` | Attach config |
| `Peekaboo.enabled` | Toggle capture globally |
| `Peekaboo.clear()` | Wipe the buffer |

## Example

See [`example/`](example/) for a runnable demo that fires a few API calls and logs events.

```bash
cd example
flutter run
```

## Versioning

Semver, starting at `0.1.0`. Breaking changes to theme fields or API bump the minor until `1.0.0`.

## License

MIT © rai-ms
