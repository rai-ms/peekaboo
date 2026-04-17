import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'log_types.dart';
import 'peekaboo_theme.dart';

/// Full-height detail sheet for a single log entry. For API entries it
/// tabs between **Request** (method + URL + headers + body) and
/// **Response** (headers + body). For socket / app entries it just
/// shows the body. Every section gets its own copy-to-clipboard
/// button; there's also a Copy cURL shortcut and a Copy all that
/// dumps the entire entry as a shareable block.
class PeekabooDetailSheet extends StatelessWidget {
  final PeekabooTheme theme;
  final LogEntry entry;

  const PeekabooDetailSheet({
    super.key,
    required this.theme,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final hasApi = entry.api != null;
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: SafeArea(
        top: false,
        child: DefaultTabController(
          length: hasApi ? 2 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(theme: theme, entry: entry),
              Divider(color: theme.panelDivider, height: 1),
              if (hasApi)
                _Tabs(theme: theme)
              else
                const SizedBox.shrink(),
              Expanded(
                child: hasApi
                    ? TabBarView(
                        children: [
                          _RequestPane(theme: theme, entry: entry),
                          _ResponsePane(theme: theme, entry: entry),
                        ],
                      )
                    : _BodyBlock(
                        theme: theme,
                        body: entry.body ?? '(no body)',
                        copyLabel: theme.label('copy', 'Copy'),
                      ),
              ),
              _ActionBar(theme: theme, entry: entry),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PeekabooTheme theme;
  final LogEntry entry;
  const _Header({required this.theme, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Pill(label: entry.channel.label, color: theme.colorForLevel(entry.level)),
                    const SizedBox(width: 6),
                    if (entry.statusText.isNotEmpty)
                      _Pill(label: entry.statusText, color: theme.panelTextMuted),
                    if (entry.durationText.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _Pill(label: entry.durationText, color: theme.panelTextMuted),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      entry.timeText,
                      style: TextStyle(color: theme.panelTextMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  entry.title,
                  style: TextStyle(
                    color: theme.panelTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (entry.api?.url != null) ...[
                  const SizedBox(height: 4),
                  SelectableText(
                    entry.api!.url!,
                    style: TextStyle(
                      color: theme.panelTextMuted,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.panelTextPrimary),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final PeekabooTheme theme;
  const _Tabs({required this.theme});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      indicatorColor: theme.panelAccent,
      labelColor: theme.panelTextPrimary,
      unselectedLabelColor: theme.panelTextMuted,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      tabs: [
        Tab(text: theme.label('tabRequest', 'Request')),
        Tab(text: theme.label('tabResponse', 'Response')),
      ],
    );
  }
}

class _RequestPane extends StatelessWidget {
  final PeekabooTheme theme;
  final LogEntry entry;
  const _RequestPane({required this.theme, required this.entry});

  @override
  Widget build(BuildContext context) {
    final api = entry.api!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _Section(
          theme: theme,
          title: theme.label('sectionHeaders', 'Headers'),
          body: _formatHeaders(api.requestHeaders),
        ),
        if (api.requestBody != null && api.requestBody!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Section(
            theme: theme,
            title: theme.label('sectionBody', 'Body'),
            body: api.requestBody!,
          ),
        ],
      ],
    );
  }
}

class _ResponsePane extends StatelessWidget {
  final PeekabooTheme theme;
  final LogEntry entry;
  const _ResponsePane({required this.theme, required this.entry});

  @override
  Widget build(BuildContext context) {
    final api = entry.api!;
    final body = entry.body ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if (api.responseHeaders.isNotEmpty) ...[
          _Section(
            theme: theme,
            title: theme.label('sectionHeaders', 'Headers'),
            body: _formatHeaders(api.responseHeaders),
          ),
          const SizedBox(height: 14),
        ],
        _Section(
          theme: theme,
          title: theme.label('sectionBody', 'Body'),
          body: body.isEmpty ? '(empty)' : body,
        ),
      ],
    );
  }
}

String _formatHeaders(Map<String, String> headers) {
  if (headers.isEmpty) return '(none)';
  final entries = headers.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => '${e.key}: ${e.value}').join('\n');
}

class _Section extends StatelessWidget {
  final PeekabooTheme theme;
  final String title;
  final String body;
  const _Section({required this.theme, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: theme.panelTextMuted,
                  fontSize: 10,
                  letterSpacing: 0.12 * 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.copy, color: theme.panelTextMuted, size: 16),
              onPressed: () => _copy(context, body),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.chipBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            body,
            style: TextStyle(
              color: theme.panelTextPrimary,
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _BodyBlock extends StatelessWidget {
  final PeekabooTheme theme;
  final String body;
  final String copyLabel;
  const _BodyBlock({required this.theme, required this.body, required this.copyLabel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _Section(theme: theme, title: copyLabel, body: body),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  final PeekabooTheme theme;
  final LogEntry entry;
  const _ActionBar({required this.theme, required this.entry});

  @override
  Widget build(BuildContext context) {
    final api = entry.api;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: theme.panelHeaderColor,
        border: Border(top: BorderSide(color: theme.panelDivider)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (api != null)
            _ActionButton(
              theme: theme,
              icon: Icons.terminal,
              label: theme.label('copyCurl', 'Copy cURL'),
              onTap: () => _copy(context, api.asCurl()),
            ),
          if (entry.body != null && entry.body!.isNotEmpty)
            _ActionButton(
              theme: theme,
              icon: Icons.download,
              label: theme.label('copyResponse', 'Copy response'),
              onTap: () => _copy(context, entry.body!),
            ),
          _ActionButton(
            theme: theme,
            icon: Icons.content_copy,
            label: theme.label('copyAll', 'Copy all'),
            onTap: () => _copy(context, entry.asShareText()),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final PeekabooTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.chipBackgroundSelected,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.chipTextSelected, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: theme.chipTextSelected,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
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

void _copy(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    const SnackBar(
      content: Text('Copied'),
      duration: Duration(milliseconds: 900),
    ),
  );
}
