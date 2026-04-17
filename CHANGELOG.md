## 0.2.1 — 2026-04-17

**Fix: row taps were getting swallowed on noisy streams.**

Two independent bugs, same symptom ("tap does nothing"):

1. **Rebuild storm cancelling gestures.** `PeekabooStore.add` was
   pushing a new emit on every log entry — on a chatty socket
   that's easily 20 emits/sec. Each emit rebuilds the overlay's
   ListView, disposing row widgets mid-tap and killing the InkWell's
   TapGestureRecognizer before pointer-up.

   Fix: coalesce emits into one broadcast per animation frame via
   `SchedulerBinding.scheduleFrameCallback`. The overlay stays live,
   taps survive.

   Also added a stable `ValueKey('${channel}/${micros}')` on every
   `_Row` so the InkWell's state (and recognizer) are preserved
   across list rebuilds.

2. **Gesture-arena starvation.** The panel used to wrap its content
   in `GestureDetector(onTap: () {})` as a blocker for the outer
   dismiss. That dummy recognizer competed with every child InkWell
   in the arena and often won, silently consuming the tap.

   Replaced with a `Stack` where the dim overlay is a SIBLING of
   the panel content. Only the dim area has a dismiss `GestureDetector`;
   panel content has no competing recognizers above the rows.

## 0.2.0 — 2026-04-17

**Richer detail panel.** Tapping any row now opens a full-height sheet
with everything a developer needs to attach to a bug report.

- New `ApiDetails` payload carried on every API entry — full URL,
  method, request headers, request body, response headers. Populated
  automatically by `PeekabooDioInterceptor`.
- The detail sheet is now a `DefaultTabController` with two tabs for
  API entries — **Request** (method/URL, headers, body) and
  **Response** (headers, body). Socket / app entries keep the single-
  body view.
- Three action buttons on the bottom bar:
  - **Copy cURL** — regenerates a pastable `curl` command from the
    request (method, headers, body, URL), shell-escaped.
  - **Copy response** — just the response body.
  - **Copy all** — the full entry as a shareable block (timestamps,
    status, URL, request headers, request body, response).
- Per-section copy icons on every Headers / Body block for
  one-property-at-a-time copying.
- New `LogEntry.asShareText()` helper — same format the Copy-all
  button uses, exposed on the public API.
- New theme `labels` keys: `tabRequest`, `tabResponse`,
  `sectionHeaders`, `sectionBody`, `copyCurl`, `copyResponse`,
  `copyAll`, `copy`. All fall back to English when unset.
- `PeekabooDetailSheet` widget exported so callers can launch it
  manually (long-press menu, Sentry-style "attach recent log" flow).

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
