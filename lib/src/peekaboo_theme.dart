import 'package:flutter/material.dart';

import 'log_types.dart';

/// Visual + behaviour config for the overlay. Pass an instance to
/// [PeekabooOverlay] to override any subset — unset fields fall back to
/// [PeekabooTheme.defaults], which looks at home on dark-theme apps.
///
/// ```dart
/// PeekabooOverlay(
///   theme: const PeekabooTheme(
///     floatingButtonColor: Colors.pink,
///     panelBackground: Color(0xFF1A1A1F),
///   ),
///   child: child,
/// )
/// ```
@immutable
class PeekabooTheme {
  // ── Floating eye button ────────────────────────────────────────────
  final Color floatingButtonColor;
  final Color floatingButtonErrorColor;
  final Color floatingButtonIconColor;
  final double floatingButtonSize;
  final IconData floatingButtonIcon;
  final BoxShadow floatingButtonShadow;

  // ── Panel shell ────────────────────────────────────────────────────
  final Color panelBackground;
  final Color panelHeaderColor;
  final Color panelTextPrimary;
  final Color panelTextMuted;
  final Color panelDivider;
  final Color panelAccent;

  // ── Per-level row tint ─────────────────────────────────────────────
  final Color levelDebugColor;
  final Color levelInfoColor;
  final Color levelWarningColor;
  final Color levelErrorColor;

  // ── Filter chip ────────────────────────────────────────────────────
  final Color chipBackground;
  final Color chipBackgroundSelected;
  final Color chipText;
  final Color chipTextSelected;

  // ── Behaviour ──────────────────────────────────────────────────────
  /// Localised label overrides — pass `{ 'clear': 'Saaf karo' }` etc.
  /// Unset keys render the english fallback.
  final Map<String, String> labels;

  const PeekabooTheme({
    this.floatingButtonColor = const Color(0xFF111827),
    this.floatingButtonErrorColor = const Color(0xFFDC2626),
    this.floatingButtonIconColor = Colors.white,
    this.floatingButtonSize = 52,
    this.floatingButtonIcon = Icons.remove_red_eye_outlined,
    this.floatingButtonShadow = const BoxShadow(
      color: Color(0x33000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
    this.panelBackground = const Color(0xFF0F172A),
    this.panelHeaderColor = const Color(0xFF1E293B),
    this.panelTextPrimary = Colors.white,
    this.panelTextMuted = const Color(0xFF94A3B8),
    this.panelDivider = const Color(0xFF1E293B),
    this.panelAccent = const Color(0xFFEC135B),
    this.levelDebugColor = const Color(0xFF64748B),
    this.levelInfoColor = const Color(0xFF10B981),
    this.levelWarningColor = const Color(0xFFF59E0B),
    this.levelErrorColor = const Color(0xFFEF4444),
    this.chipBackground = const Color(0xFF1E293B),
    this.chipBackgroundSelected = const Color(0xFFEC135B),
    this.chipText = const Color(0xFF94A3B8),
    this.chipTextSelected = Colors.white,
    this.labels = const {},
  });

  /// Out-of-the-box defaults — works on dark-mode apps without any
  /// tuning. Callers that need a different palette pass their own
  /// [PeekabooTheme] instance.
  static const PeekabooTheme defaults = PeekabooTheme();

  Color colorForLevel(LogLevel level) => switch (level) {
        LogLevel.debug => levelDebugColor,
        LogLevel.info => levelInfoColor,
        LogLevel.warning => levelWarningColor,
        LogLevel.error => levelErrorColor,
      };

  String label(String key, String fallback) => labels[key] ?? fallback;

  PeekabooTheme copyWith({
    Color? floatingButtonColor,
    Color? floatingButtonErrorColor,
    Color? floatingButtonIconColor,
    double? floatingButtonSize,
    IconData? floatingButtonIcon,
    BoxShadow? floatingButtonShadow,
    Color? panelBackground,
    Color? panelHeaderColor,
    Color? panelTextPrimary,
    Color? panelTextMuted,
    Color? panelDivider,
    Color? panelAccent,
    Color? levelDebugColor,
    Color? levelInfoColor,
    Color? levelWarningColor,
    Color? levelErrorColor,
    Color? chipBackground,
    Color? chipBackgroundSelected,
    Color? chipText,
    Color? chipTextSelected,
    Map<String, String>? labels,
  }) {
    return PeekabooTheme(
      floatingButtonColor: floatingButtonColor ?? this.floatingButtonColor,
      floatingButtonErrorColor:
          floatingButtonErrorColor ?? this.floatingButtonErrorColor,
      floatingButtonIconColor:
          floatingButtonIconColor ?? this.floatingButtonIconColor,
      floatingButtonSize: floatingButtonSize ?? this.floatingButtonSize,
      floatingButtonIcon: floatingButtonIcon ?? this.floatingButtonIcon,
      floatingButtonShadow: floatingButtonShadow ?? this.floatingButtonShadow,
      panelBackground: panelBackground ?? this.panelBackground,
      panelHeaderColor: panelHeaderColor ?? this.panelHeaderColor,
      panelTextPrimary: panelTextPrimary ?? this.panelTextPrimary,
      panelTextMuted: panelTextMuted ?? this.panelTextMuted,
      panelDivider: panelDivider ?? this.panelDivider,
      panelAccent: panelAccent ?? this.panelAccent,
      levelDebugColor: levelDebugColor ?? this.levelDebugColor,
      levelInfoColor: levelInfoColor ?? this.levelInfoColor,
      levelWarningColor: levelWarningColor ?? this.levelWarningColor,
      levelErrorColor: levelErrorColor ?? this.levelErrorColor,
      chipBackground: chipBackground ?? this.chipBackground,
      chipBackgroundSelected:
          chipBackgroundSelected ?? this.chipBackgroundSelected,
      chipText: chipText ?? this.chipText,
      chipTextSelected: chipTextSelected ?? this.chipTextSelected,
      labels: labels ?? this.labels,
    );
  }
}
