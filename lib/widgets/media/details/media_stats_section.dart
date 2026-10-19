import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/widgets/media/details/media_section_header.dart';
import 'package:moesync/widgets/media/details/media_stat_item.dart';
import 'package:moesync/widgets/media/details/media_vertical_divider.dart';
import 'package:flutter/material.dart';

class MediaStatsSection extends StatelessWidget {
  const MediaStatsSection({
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
          MediaSectionHeader(
            theme: theme,
            title: AppLocalizations.of(context).stats,
            icon: Icons.show_chart_rounded,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: MediaStatItem(
                    theme: theme,
                    icon: Icons.bar_chart_rounded,
                    label: data.rank != null ? '#${data.rank}' : '-',
                    sublabel: AppLocalizations.of(context).ranking,
                  ),
                ),
                MediaVerticalDivider(theme: theme),
                Expanded(
                  child: MediaStatItem(
                    theme: theme,
                    icon: Icons.favorite_border_rounded,
                    label: data.favorites != null
                        ? formatNumber(data.favorites!)
                        : '-',
                    sublabel: AppLocalizations.of(context).favorites,
                  ),
                ),
                MediaVerticalDivider(theme: theme),
                Expanded(
                  child: MediaStatItem(
                    theme: theme,
                    icon: Icons.people_outline_rounded,
                    label: data.popularity != null
                        ? formatNumber(data.popularity!)
                        : '-',
                    sublabel: AppLocalizations.of(context).popularity,
                  ),
                ),
                MediaVerticalDivider(theme: theme),
                Expanded(
                  child: MediaStatItem(
                    theme: theme,
                    icon: Icons.trending_up_rounded,
                    label: data.trending != null ? '#${data.trending}' : '-',
                    sublabel: AppLocalizations.of(context).trending,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
