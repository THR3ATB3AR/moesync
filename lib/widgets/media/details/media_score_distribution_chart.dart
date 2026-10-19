import 'package:moesync/models/media_detail_data.dart';
import 'package:flutter/material.dart';

class MediaScoreDistributionChart extends StatelessWidget {
  const MediaScoreDistributionChart({
    super.key,
    required this.theme,
    required this.scoreDist,
  });

  final ThemeData theme;
  final Map<int, int> scoreDist;

  @override
  Widget build(BuildContext context) {
    final maxAmount = scoreDist.values.isEmpty
        ? 1
        : scoreDist.values.reduce((a, b) => a > b ? a : b);
    final sortedScores = scoreDist.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: sortedScores.map((scoreKey) {
            final amount = scoreDist[scoreKey] ?? 0;
            final ratio = maxAmount > 0 ? (amount / maxAmount) : 0.0;
            final barHeight = (ratio * 70).clamp(4.0, 70.0);

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formatShortNumber(amount),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: barHeight,
                    width: 12,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$scoreKey',
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
