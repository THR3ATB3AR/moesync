import 'package:moesync/models/media_detail_data.dart';
import 'package:flutter/material.dart';

class MediaGenresRow extends StatelessWidget {
  const MediaGenresRow({super.key, required this.theme, required this.data});

  final ThemeData theme;
  final MediaDetailData data;

  @override
  Widget build(BuildContext context) {
    final allTags = [...data.genres, ...data.tags];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: allTags.take(12).map((tag) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              tag,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
