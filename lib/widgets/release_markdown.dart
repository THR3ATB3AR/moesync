import 'package:flutter/material.dart';

class ReleaseMarkdown extends StatelessWidget {
  const ReleaseMarkdown({required this.body, super.key});

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = body.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rawLine in lines)
          if (rawLine.trim().isNotEmpty) _buildLine(rawLine, theme),
      ],
    );
  }

  Widget _buildLine(String rawLine, ThemeData theme) {
    final line = rawLine.trim();
    final headingMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
    if (headingMatch != null) {
      final isSection = headingMatch.group(1)!.length == 3;
      return Padding(
        padding: EdgeInsets.only(top: isSection ? 12 : 6, bottom: 4),
        child: Text(
          _stripMarkdown(headingMatch.group(2)!),
          style: isSection
              ? theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
        ),
      );
    }
    if (line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, top: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: theme.textTheme.bodyMedium),
            Expanded(
              child: Text(
                _stripMarkdown(line.substring(2)),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(_stripMarkdown(line), style: theme.textTheme.bodyMedium),
    );
  }

  String _stripMarkdown(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\(https?://[^)]+\)'),
          (match) => match.group(1)!,
        )
        .replaceAll('**', '')
        .replaceAll('`', '');
  }
}
