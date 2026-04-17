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
