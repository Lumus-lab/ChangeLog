import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

MarkdownStyleSheet buildAIMarkdownStyle(BuildContext context) {
  final theme = Theme.of(context);
  final primary = theme.colorScheme.primary;

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: const TextStyle(fontSize: 16, height: 1.7),
    pPadding: const EdgeInsets.only(bottom: 10),
    h3: TextStyle(
      color: primary,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      height: 1.4,
    ),
    h3Padding: const EdgeInsets.only(top: 14, bottom: 6),
    strong: const TextStyle(fontWeight: FontWeight.w700),
    blockSpacing: 12,
    blockquote: TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
      fontSize: 15,
      height: 1.6,
    ),
    blockquotePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    blockquoteDecoration: BoxDecoration(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border(
        left: BorderSide(color: primary.withValues(alpha: 0.7), width: 3),
      ),
    ),
  );
}
