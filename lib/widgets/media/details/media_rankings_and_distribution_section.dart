import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/widgets/media/details/media_score_distribution_chart.dart';
import 'package:moesync/widgets/media/details/media_section_header.dart';
import 'package:moesync/widgets/media/details/media_status_distribution_bar.dart';
import 'package:flutter/material.dart';

class MediaRankingsAndDistributionSection extends StatelessWidget {
  const MediaRankingsAndDistributionSection({
    super.key,
    required this.context,
    required this.theme,
    required this.data,
  });

  final BuildContext context;
  final ThemeData theme;
  final MediaDetailData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.rankings.isNotEmpty) ...[
            MediaSectionHeader(
              theme: theme,
              title: AppLocalizations.of(context).rankings,
              icon: Icons.leaderboard_rounded,
            ),
            const SizedBox(height: 10),
            Column(
              children: data.rankings.take(6).map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        r.isStar ? Icons.star_rounded : Icons.favorite_rounded,
                        color: r.isStar ? Colors.amber : Colors.pinkAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '#${r.rank} ${r.context}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          if (data.statusDistribution.isNotEmpty) ...[
            MediaSectionHeader(
              theme: theme,
              title: AppLocalizations.of(context).statusDistribution,
              icon: Icons.show_chart_rounded,
            ),
            const SizedBox(height: 10),
            MediaStatusDistributionBar(
              context: context,
              theme: theme,
              dist: data.statusDistribution,
            ),
            const SizedBox(height: 20),
          ],

          if (data.scoreDistribution.isNotEmpty) ...[
            MediaSectionHeader(
              theme: theme,
              title: AppLocalizations.of(context).scoreDistribution,
            ),
            const SizedBox(height: 10),
            MediaScoreDistributionChart(
              theme: theme,
              scoreDist: data.scoreDistribution,
            ),
          ],
        ],
      ),
    );
  }
}
