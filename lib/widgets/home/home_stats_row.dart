import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/home/home_stat_card.dart';
import 'package:flutter/material.dart';

class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({
    super.key,
    required this.context,
    required this.theme,
    required this.animeCount,
    required this.mangaCount,
    required this.completed,
  });

  final BuildContext context;
  final ThemeData theme;
  final int animeCount;
  final int mangaCount;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HomeStatCard(
          theme: theme,
          label: AppLocalizations.of(context).watching,
          value: '$animeCount',
          icon: Icons.tv_rounded,
        ),
        const SizedBox(width: 10),
        HomeStatCard(
          theme: theme,
          label: AppLocalizations.of(context).reading,
          value: '$mangaCount',
          icon: Icons.auto_stories_rounded,
        ),
        const SizedBox(width: 10),
        HomeStatCard(
          theme: theme,
          label: AppLocalizations.of(context).completed,
          value: '$completed',
          icon: Icons.task_alt_rounded,
        ),
      ],
    );
  }
}
