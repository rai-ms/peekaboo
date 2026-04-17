## 0.1.0 — 2026-04-17

- Initial release.
- `PeekabooOverlay` — draggable floating eye + slide-up panel.
- `PeekabooDioInterceptor` — captures Dio requests/responses/errors.
- `PeekabooSocket.outgoing/incoming/error` — socket.io helper.
- `Peekaboo.d/i/w/e` — app-level log helpers.
- `PeekabooTheme` — full colour / icon / label customisation with
  `copyWith` + sensible dark-mode defaults.
- Capped ring buffer (500 entries), broadcast stream for live updates,
  debug-only by default (`Peekaboo.enabled`).
