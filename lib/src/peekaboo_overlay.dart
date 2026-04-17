import 'package:flutter/material.dart';

import 'log_types.dart';
import 'peekaboo_panel.dart';
import 'peekaboo_store.dart';
import 'peekaboo_theme.dart';

/// Wraps your app root with a draggable floating eye. Tapping opens the
/// log panel; long-press wipes the buffer. Position is preserved across
/// rebuilds as long as [PeekabooOverlay] stays mounted.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => PeekabooOverlay(child: child ?? const SizedBox()),
/// )
/// ```
///
/// Pass a [PeekabooTheme] to restyle; hidden automatically when
/// [PeekabooStore.instance.isEnabled] is false (default: debug only).
class PeekabooOverlay extends StatefulWidget {
  final Widget child;
  final PeekabooTheme theme;
  final Offset initialPosition;

  const PeekabooOverlay({
    super.key,
    required this.child,
    this.theme = PeekabooTheme.defaults,
    this.initialPosition = const Offset(16, 120),
  });

  @override
  State<PeekabooOverlay> createState() => _PeekabooOverlayState();
}

class _PeekabooOverlayState extends State<PeekabooOverlay> {
  late Offset _pos = widget.initialPosition;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (!PeekabooStore.instance.isEnabled) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: _pos.dx,
          top: _pos.dy,
          child: _DraggableEye(
            theme: widget.theme,
            onDrag: (delta) => setState(() => _pos += delta),
            onTap: () => setState(() => _open = true),
            onLongPress: PeekabooStore.instance.clear,
          ),
        ),
        if (_open)
          Positioned.fill(
            child: PeekabooPanel(
              theme: widget.theme,
              onClose: () => setState(() => _open = false),
            ),
          ),
      ],
    );
  }
}

class _DraggableEye extends StatelessWidget {
  final PeekabooTheme theme;
  final void Function(Offset delta) onDrag;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _DraggableEye({
    required this.theme,
    required this.onDrag,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LogEntry>>(
      stream: PeekabooStore.instance.stream,
      initialData: PeekabooStore.instance.entries,
      builder: (context, snap) {
        final entries = snap.data ?? const <LogEntry>[];
        final errors = entries.where((e) => e.level.isError).length;
        final bg = errors > 0
            ? theme.floatingButtonErrorColor
            : theme.floatingButtonColor;
        return GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          onPanUpdate: (d) => onDrag(d.delta),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: theme.floatingButtonSize,
              height: theme.floatingButtonSize,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                boxShadow: [theme.floatingButtonShadow],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    theme.floatingButtonIcon,
                    color: theme.floatingButtonIconColor,
                    size: theme.floatingButtonSize * 0.42,
                  ),
                  if (errors > 0)
                    Positioned(
                      top: theme.floatingButtonSize * 0.12,
                      right: theme.floatingButtonSize * 0.12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.floatingButtonIconColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$errors',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: theme.floatingButtonErrorColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
