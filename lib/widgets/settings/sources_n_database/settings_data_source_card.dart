import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/service_badge.dart';
import 'package:moesync/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsDataSourceCard extends StatelessWidget {
  const SettingsDataSourceCard({
    super.key,
    required this.context,
    required this.ref,
    required this.theme,
    required this.type,
  });

  final BuildContext context;
  final WidgetRef ref;
  final ThemeData theme;
  final MediaType type;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(dataSourceSettingsProvider);
    final isAnime = type == MediaType.anime;
    final supported = ServiceType.forMediaType(type);

    return SettingsCard(
      icon: isAnime ? Icons.tv_rounded : Icons.auto_stories_rounded,
      title: isAnime
          ? AppLocalizations.of(context).animePreferences
          : AppLocalizations.of(context).mangaPreferences,
      subtitle: AppLocalizations.of(
        context,
      ).defaultSourceForInformationDescriptionAndSynchronization,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).defaultInformationSource,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${AppLocalizations.of(context).usedAsTheFirstSourceWhenOpeningDetailsOf} ${isAnime ? AppLocalizations.of(context).anime : AppLocalizations.of(context).manga}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ServiceType>(
            key: ValueKey(
              'info_source_${type.name}_${settings.getInfoSource(type).name}',
            ),
            initialValue: supported.contains(settings.getInfoSource(type))
                ? settings.getInfoSource(type)
                : supported.first,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
            isExpanded: true,
            items: supported.map((s) {
              return DropdownMenuItem<ServiceType>(
                value: s,
                child: Row(
                  children: [
                    ServiceBadge(service: s, size: 18),
                    const SizedBox(width: 8),
                    Text(s.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                ref
                    .read(dataSourceSettingsProvider.notifier)
                    .setInfoSource(type, val);
              }
            },
          ),
          const SizedBox(height: 16),
          Divider(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),

          Text(
            AppLocalizations.of(context).defaultDescriptionSource,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(
              context,
            ).selectTheServiceWhoseDescriptionShouldBeDisplayedFirst,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ServiceType?>(
            key: ValueKey(
              'desc_source_${type.name}_${settings.getDescriptionSource(type)?.name ?? "auto"}',
            ),
            initialValue: settings.getDescriptionSource(type),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
            isExpanded: true,
            items: [
              DropdownMenuItem<ServiceType?>(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18),
                    SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).automaticSameAsInfoSource,
                    ),
                  ],
                ),
              ),
              ...supported.map((s) {
                return DropdownMenuItem<ServiceType?>(
                  value: s,
                  child: Row(
                    children: [
                      ServiceBadge(service: s, size: 18),
                      const SizedBox(width: 8),
                      Text(s.displayName),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (val) {
              ref
                  .read(dataSourceSettingsProvider.notifier)
                  .setDescriptionSource(type, val);
            },
          ),
          const SizedBox(height: 16),
          Divider(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),

          Text(
            AppLocalizations.of(context).defaultSynchronizationSource,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${AppLocalizations.of(context).defaultPrimaryServiceDuringSynchronizationOf} ${isAnime ? AppLocalizations.of(context).anime : AppLocalizations.of(context).manga}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ServiceType>(
            key: ValueKey(
              'sync_source_${type.name}_${settings.getSyncSource(type).name}',
            ),
            initialValue: supported.contains(settings.getSyncSource(type))
                ? settings.getSyncSource(type)
                : supported.first,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
            isExpanded: true,
            items: supported.map((s) {
              return DropdownMenuItem<ServiceType>(
                value: s,
                child: Row(
                  children: [
                    ServiceBadge(service: s, size: 18),
                    const SizedBox(width: 8),
                    Text(s.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                ref
                    .read(dataSourceSettingsProvider.notifier)
                    .setSyncSource(type, val);
                final currentSync = ref.read(syncProvider);
                if (currentSync.mediaType == type) {
                  ref.read(syncProvider.notifier).setPrimary(val);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
