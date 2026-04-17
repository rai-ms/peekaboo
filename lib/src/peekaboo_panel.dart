import 'package:flutter/material.dart';

import 'log_types.dart';
import 'peekaboo_detail_sheet.dart';
import 'peekaboo_store.dart';
import 'peekaboo_theme.dart';

/// Full-screen slide-up panel. Owns the filter state (channel chips +
/// search text) and renders the row list + a detail sheet on row-tap.
class PeekabooPanel extends StatefulWidget {
  final PeekabooTheme theme;
  final VoidCallback onClose;
  const PeekabooPanel({
    super.key,
    required this.theme,
    required this.onClose,
  });

  @override
  State<PeekabooPanel> createState() => _PeekabooPanelState();
}

class _PeekabooPanelState extends State<PeekabooPanel> {
  final Set<LogChannel> _selected = LogChannel.values.toSet();
  String _search = '';

  PeekabooTheme get _t => widget.theme;

  List<LogEntry> _filter(List<LogEntry> all) {
    final q = _search.toLowerCase();
    return all.where((e) {
      if (!_selected.contains(e.channel)) return false;
      if (q.isEmpty) return true;
      return e.title.toLowerCase().contains(q) ||
          (e.body?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      child: GestureDetector(
        onTap: widget.onClose,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: FractionallySizedBox(
              heightFactor: 0.75,
              child: Container(
                decoration: BoxDecoration(
                  color: _t.panelBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      _Header(theme: _t, onClose: widget.onClose),
                      _Filters(
                        theme: _t,
                        selected: _selected,
                        onToggle: (c) => setState(() {
                          _selected.contains(c)
                              ? _selected.remove(c)
                              : _selected.add(c);
                        }),
                      ),
                      _SearchField(
                        theme: _t,
                        onChanged: (v) => setState(() => _search = v),
                      ),
                      Expanded(
                        child: StreamBuilder<List<LogEntry>>(
                          stream: PeekabooStore.instance.stream,
                          initialData: PeekabooStore.instance.entries,
                          builder: (context, snap) {
                            final filtered = _filter(snap.data ?? const []);
                            if (filtered.isEmpty) {
                              return Center(
                                child: Text(
                                  _t.label('empty', 'No logs'),
                                  style: TextStyle(color: _t.panelTextMuted),
                                ),
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: _t.panelDivider),
                              itemBuilder: (_, i) => _Row(
                                theme: _t,
                                entry: filtered[i],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PeekabooTheme theme;
  final VoidCallback onClose;
  const _Header({required this.theme, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(color: theme.panelHeaderColor),
      child: Row(
        children: [
          Icon(Icons.remove_red_eye_outlined, color: theme.panelTextPrimary),
          const SizedBox(width: 10),
          Text(
            theme.label('title', 'Peekaboo'),
            style: TextStyle(
              color: theme.panelTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: PeekabooStore.instance.clear,
            icon: Icon(Icons.delete_outline, color: theme.panelTextMuted),
            label: Text(
              theme.label('clear', 'Clear'),
              style: TextStyle(color: theme.panelTextMuted),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.panelTextPrimary),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final PeekabooTheme theme;
  final Set<LogChannel> selected;
  final void Function(LogChannel) onToggle;
  const _Filters({
    required this.theme,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Wrap(
        spacing: 8,
        children: LogChannel.values.map((c) {
          final isOn = selected.contains(c);
          return GestureDetector(
            onTap: () => onToggle(c),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOn ? theme.chipBackgroundSelected : theme.chipBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                c.label,
                style: TextStyle(
                  color: isOn ? theme.chipTextSelected : theme.chipText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final PeekabooTheme theme;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.theme, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: theme.panelTextPrimary, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: theme.label('search', 'Search title or body…'),
          hintStyle: TextStyle(color: theme.panelTextMuted, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: theme.panelTextMuted, size: 18),
          filled: true,
          fillColor: theme.chipBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final PeekabooTheme theme;
  final LogEntry entry;
  const _Row({required this.theme, required this.entry});

  @override
  Widget build(BuildContext context) {
    final accent = theme.colorForLevel(entry.level);
    return InkWell(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 3, height: 28, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(
                        text: entry.channel.label,
                        color: accent,
                      ),
                      const SizedBox(width: 6),
                      if (entry.statusText.isNotEmpty)
                        _Badge(
                          text: entry.statusText,
                          color: theme.panelTextMuted,
                        ),
                      const Spacer(),
                      Text(
                        entry.timeText,
                        style: TextStyle(
                          color: theme.panelTextMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.panelTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (entry.durationText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.durationText,
                        style: TextStyle(
                          color: theme.panelTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    // Apps that wire their routing through a router (GoRouter, beamer,
    // …) usually have only a root Navigator — a nested lookup from
    // the panel's captured context throws "context does not include a
    // Navigator". useRootNavigator:true targets that root explicitly
    // so the detail sheet works in every routing setup.
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.panelBackground,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => PeekabooDetailSheet(theme: theme, entry: entry),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

