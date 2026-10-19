import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/media/details/media_dist_pill.dart';
import 'package:flutter/material.dart';

class MediaStatusDistributionBar extends StatelessWidget {
  const MediaStatusDistributionBar({
    super.key,
    required this.context,
    required this.theme,
    required this.dist,
  });

  final BuildContext context;
  final ThemeData theme;
  final Map<String, int> dist;

  @override
  Widget build(BuildContext context) {
    final current = dist['current'] ?? dist['watching'] ?? dist['reading'] ?? 0;
    final planning =
        dist['planning'] ?? dist['plan_to_watch'] ?? dist['plan_to_read'] ?? 0;
    final completed = dist['completed'] ?? 0;
    final paused = dist['paused'] ?? dist['on_hold'] ?? 0;
    final dropped = dist['dropped'] ?? 0;
    final total = current + planning + completed + paused + dropped;

    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MediaDistPill(
              theme: theme,
              label: AppLocalizations.of(context).current,
              value: current,
              color: Colors.lightGreen,
            ),
            MediaDistPill(
              theme: theme,
              label: AppLocalizations.of(context).planning,
              value: planning,
              color: Colors.brown.shade400,
            ),
            MediaDistPill(
              theme: theme,
              label: AppLocalizations.of(context).completed,
              value: completed,
              color: Colors.indigo.shade300,
            ),
            if (paused > 0)
              MediaDistPill(
                theme: theme,
                label: AppLocalizations.of(context).onHold,
                value: paused,
                color: Colors.amber,
              ),
            if (dropped > 0)
              MediaDistPill(
                theme: theme,
                label: AppLocalizations.of(context).dropped,
                value: dropped,
                color: Colors.redAccent,
              ),
          ],
        ),
        const SizedBox(height: 10),

        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (current > 0)
                  Expanded(
                    flex: current,
                    child: Container(color: Colors.lightGreen),
                  ),
                if (planning > 0)
                  Expanded(
                    flex: planning,
                    child: Container(color: Colors.brown.shade400),
                  ),
                if (completed > 0)
                  Expanded(
                    flex: completed,
                    child: Container(color: Colors.indigo.shade300),
                  ),
                if (paused > 0)
                  Expanded(
                    flex: paused,
                    child: Container(color: Colors.amber),
                  ),
                if (dropped > 0)
                  Expanded(
                    flex: dropped,
                    child: Container(color: Colors.redAccent),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context).totalCount(total),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
