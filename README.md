# peekaboo 👀

A draggable in-app log overlay for Flutter. See every HTTP request, every Socket.IO event, and every `Peekaboo.d/i/w/e` line your app produces — right on top of whatever screen you're debugging. Zero-setup for QA builds, debug-only by default.

## Install

Add to `pubspec.yaml` (via Git for now — pub.dev release coming):

```yaml
dependencies:
  peekaboo:
    git:
      url: https://github.com/rai-ms/peekaboo
      ref: main
```

## Wire it up

```dart
import 'package:peekaboo/peekaboo.dart';

// 1. Wrap your app root
MaterialApp(
  builder: (context, child) => PeekabooOverlay(
    child: child ?? const SizedBox(),
  ),
);

// 2. Attach the Dio interceptor
dio.interceptors.add(PeekabooDioInterceptor());

// 3. Forward socket traffic
socket.onAny((event, data) => PeekabooSocket.incoming(event, data));
// before each emit:
PeekabooSocket.outgoing(eventName, payload);
socket.emit(eventName, payload);

// 4. Log from anywhere in your app
Peekaboo.d('Fetching feed…');
Peekaboo.w('Unexpected empty list');
Peekaboo.e('Login failed', body: err.toString());
```

## Customize the look

Every colour, icon, label, and dimension is on `PeekabooTheme`. Pass your own instance:

```dart
PeekabooOverlay(
  theme: PeekabooTheme.defaults.copyWith(
    floatingButtonColor: const Color(0xFF7B1F70),
    floatingButtonErrorColor: const Color(0xFFEC135B),
    panelAccent: const Color(0xFFEC135B),
    panelBackground: const Color(0xFF0F0B1A),
    labels: {
      'title': 'Jalwa Logs',
      'clear': 'Saaf',
      'search': 'Khojo…',
    },
  ),
  child: child ?? const SizedBox(),
)
```

| Section | Fields |
|---|---|
| Floating eye | `floatingButtonColor`, `floatingButtonErrorColor`, `floatingButtonIconColor`, `floatingButtonSize`, `floatingButtonIcon`, `floatingButtonShadow` |
| Panel shell | `panelBackground`, `panelHeaderColor`, `panelTextPrimary`, `panelTextMuted`, `panelDivider`, `panelAccent` |
| Row tint | `levelDebugColor`, `levelInfoColor`, `levelWarningColor`, `levelErrorColor` |
| Filter chip | `chipBackground`, `chipBackgroundSelected`, `chipText`, `chipTextSelected` |
| i18n | `labels` map: keys `title`, `clear`, `search`, `empty` |

## Controls

- **Tap** the floating eye → open panel
- **Long-press** the eye → clear buffer
- **Drag** the eye → move anywhere on screen
- Panel: filter chips (API / SOCKET / APP) + search box + tap any row to see full body (with copy)
- Error count badge on the eye turns red when >0 errors are in the buffer

## Toggle in release

The overlay is debug-only by default. Flip it on for a QA build:

```dart
void main() {
  Peekaboo.enabled = true;          // or wire to a secret tap-5-times toggle
  runApp(const MyApp());
}
```

## License

MIT
