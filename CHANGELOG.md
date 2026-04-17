## 0.1.1 — 2026-04-17

- Fix: tapping a log row in router-based apps (GoRouter, beamer, …)
  threw `Navigator operation requested with a context that does not
  include a Navigator`. Both the detail bottom-sheet launcher and
  its close button now use `useRootNavigator: true` /
  `Navigator.of(context, rootNavigator: true)` so the lookup always
  resolves against the root navigator where the panel lives.

## 0.1.0 — 2026-04-17

- Initial release.
- `PeekabooOverlay` — draggable floating eye + slide-up panel.
- `PeekabooDioInterceptor` — captures Dio requests/responses/errors.
- `PeekabooSocket.outgoing/incoming/error` — socket.io helper.
- `Peekaboo.d/i/w/e` — app-level log helpers.
- `PeekabooTheme` — full colour / icon / label customisation with
  `copyWith` + sensible dark-mode defaults.
- `PeekabooConfig` — per-channel enable, per-entry filter, optional
  `onCapture` sink for forwarding entries to Sentry / Crashlytics /
  your own pipeline.
- Crash-safe — every producer, sink, and UI path wraps in `try/catch`;
  a broken `toString()` or a throwing listener cannot take the host
  app down.
- Capped ring buffer (500 entries), broadcast stream for live updates,
  debug-only by default (`Peekaboo.enabled`).
- Runnable example app in `example/`.
