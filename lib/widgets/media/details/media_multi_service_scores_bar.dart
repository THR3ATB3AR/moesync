import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/media/details/media_section_header.dart';
import 'package:moesync/widgets/service_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/media_detail_data.dart';
import '../../../models/media_item.dart';

class MediaMultiServiceScoresBar extends ConsumerStatefulWidget {
  final UnifiedMediaItem item;
  final Map<ServiceType, MediaDetailData> allServiceData;
  final ServiceType selectedService;
  final Function(ServiceType) onSelectService;
  final ThemeData theme;
  final List<ServiceType> supportedServices;

  const MediaMultiServiceScoresBar({
    super.key,
    required this.item,
    required this.allServiceData,
    required this.selectedService,
    required this.onSelectService,
    required this.theme,
    required this.supportedServices,
  });

  @override
  ConsumerState<MediaMultiServiceScoresBar> createState() =>
      _MediaMultiServiceScoresBarState();
}

class _MediaMultiServiceScoresBarState
    extends ConsumerState<MediaMultiServiceScoresBar> {
  @override
  Widget build(BuildContext context) {
    final servicesWithData = widget.supportedServices
        .where((s) => widget.allServiceData.containsKey(s))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MediaSectionHeader(
                theme: widget.theme,
                title: AppLocalizations.of(context).serviceScores,
                icon: Icons.insights_rounded,
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context).dataScoresServiceWithData(
                  servicesWithData.length,
                  widget.supportedServices.length,
                ),
                style: widget.theme.textTheme.bodySmall?.copyWith(
                  color: widget.theme.colorScheme.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.supportedServices.map((service) {
                final data = widget.allServiceData[service];
                final score = data?.score;
                final isTracked = widget.item.services.containsKey(service);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => widget.onSelectService(service),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ServiceBadgeChip(service: service, size: 16),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    service.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: widget.theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (isTracked) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 11,
                                      color: widget.theme.colorScheme.primary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (score != null) ...[
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      score.toStringAsFixed(
                                        service == ServiceType.anilist ||
                                                service == ServiceType.kitsu
                                            ? 1
                                            : 2,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: widget
                                            .theme
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ] else if (data != null) ...[
                                    Text(
                                      AppLocalizations.of(context).available,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: widget.theme.colorScheme.outline,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      AppLocalizations.of(context).noData,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: widget.theme.colorScheme.outline
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
