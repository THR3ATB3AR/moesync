import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/media_item.dart';
import '../../providers/providers.dart';
import '../service_badge.dart';

class EditMediaDialog extends ConsumerStatefulWidget {
  final UnifiedMediaItem item;

  const EditMediaDialog({super.key, required this.item});

  @override
  ConsumerState<EditMediaDialog> createState() => _EditMediaDialogState();
}

class _EditMediaDialogState extends ConsumerState<EditMediaDialog> {
  late String _status;
  late int _score;
  late int _progress;
  final Map<ServiceType, String> _serviceStatusOverrides = {};
  final Map<ServiceType, int> _serviceProgressOverrides = {};
  bool _isServiceSettingsExpanded = false;

  String _normalizeStatus(String status, bool isAnime) {
    final normalized = status.toLowerCase();
    if (normalized == 'watching' || normalized == 'reading') {
      return isAnime ? 'watching' : 'reading';
    }
    if (normalized == 'plan_to_watch' || normalized == 'plan_to_read') {
      return isAnime ? 'plan_to_watch' : 'plan_to_read';
    }
    const commonStatuses = {'completed', 'on_hold', 'dropped'};
    if (commonStatuses.contains(normalized)) return normalized;
    return isAnime ? 'plan_to_watch' : 'plan_to_read';
  }

  @override
  void initState() {
    super.initState();
    final isAnime = widget.item.mediaType == MediaType.anime;
    final firstItem = widget.item.services.values.firstOrNull;
    final rawStatus = firstItem?.status ?? (isAnime ? 'watching' : 'reading');
    _status = _normalizeStatus(rawStatus, isAnime);
    _score = firstItem?.score ?? 0;
    _progress = firstItem?.progress ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnime = widget.item.mediaType == MediaType.anime;

    final totalEpisodes =
        widget.item.resolvedTotalProgress ?? widget.item.maxTotalProgress;
    final int maxLimit = (totalEpisodes != null && totalEpisodes > 0)
        ? (totalEpisodes < _progress ? _progress : totalEpisodes)
        : (_progress > 100 ? _progress + 50 : 100);
    final int effectiveMax = maxLimit > 0 ? maxLimit : 1;
    final statusItems = isAnime
        ? const [
            DropdownMenuItem(value: 'watching', child: Text('Watching')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'on_hold', child: Text('On Hold')),
            DropdownMenuItem(value: 'dropped', child: Text('Dropped')),
            DropdownMenuItem(
              value: 'plan_to_watch',
              child: Text('Plan to Watch'),
            ),
          ]
        : const [
            DropdownMenuItem(value: 'reading', child: Text('Reading')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'on_hold', child: Text('On Hold')),
            DropdownMenuItem(value: 'dropped', child: Text('Dropped')),
            DropdownMenuItem(
              value: 'plan_to_read',
              child: Text('Plan to Read'),
            ),
          ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.item.posterImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.item.posterImage,
                            width: 60,
                            height: 85,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 85,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.movie),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        if (widget.item.services.length > 1)
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(
                              () => _isServiceSettingsExpanded =
                                  !_isServiceSettingsExpanded,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: widget.item.services.keys.map((
                                        service,
                                      ) {
                                        return ServiceBadgeChip(
                                          service: service,
                                          size: 14,
                                          compact: true,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  Icon(
                                    _isServiceSettingsExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: widget.item.services.keys.map((service) {
                              return ServiceBadgeChip(
                                service: service,
                                size: 14,
                                compact: true,
                              );
                            }).toList(),
                          ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child:
                              widget.item.services.length > 1 &&
                                  _isServiceSettingsExpanded
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    children: widget.item.services.entries.map((
                                      entry,
                                    ) {
                                      final service = entry.key;
                                      final serviceItem = entry.value;
                                      final serviceStatus =
                                          _serviceStatusOverrides[service] ??
                                          _normalizeStatus(
                                            serviceItem.status,
                                            isAnime,
                                          );
                                      final serviceProgress =
                                          _serviceProgressOverrides[service] ??
                                          serviceItem.progress;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  ServiceBadgeChip(
                                                    service: service,
                                                    size: 18,
                                                    compact: true,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    service.displayName,
                                                    style: theme
                                                        .textTheme
                                                        .titleSmall,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              DropdownButtonFormField<String>(
                                                initialValue: serviceStatus,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      AppLocalizations.of(
                                                        context,
                                                      ).status,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                ),
                                                items: statusItems,
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setState(() {
                                                    _serviceStatusOverrides[service] =
                                                        value;
                                                    if (value == 'completed' &&
                                                        totalEpisodes != null &&
                                                        totalEpisodes > 0) {
                                                      _serviceProgressOverrides[service] =
                                                          totalEpisodes;
                                                    }
                                                  });
                                                },
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    isAnime
                                                        ? 'Episodes'
                                                        : 'Chapters',
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                  const Spacer(),
                                                  IconButton(
                                                    onPressed:
                                                        serviceProgress > 0
                                                        ? () => setState(
                                                            () => _serviceProgressOverrides[service] =
                                                                serviceProgress -
                                                                1,
                                                          )
                                                        : null,
                                                    icon: const Icon(
                                                      Icons.remove,
                                                    ),
                                                  ),
                                                  Text(
                                                    totalEpisodes != null &&
                                                            totalEpisodes > 0
                                                        ? '$serviceProgress / $totalEpisodes'
                                                        : '$serviceProgress',
                                                    style: theme
                                                        .textTheme
                                                        .titleSmall,
                                                  ),
                                                  IconButton(
                                                    onPressed:
                                                        totalEpisodes != null &&
                                                            serviceProgress >=
                                                                totalEpisodes
                                                        ? null
                                                        : () => setState(
                                                            () => _serviceProgressOverrides[service] =
                                                                serviceProgress +
                                                                1,
                                                          ),
                                                    icon: const Icon(Icons.add),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              Text(
                AppLocalizations.of(context).status,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                items: statusItems,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _status = val;
                      if (val == 'completed' &&
                          totalEpisodes != null &&
                          totalEpisodes > 0 &&
                          _progress < totalEpisodes) {
                        _progress = totalEpisodes;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAnime ? 'Watched Episodes' : 'Read Chapters',
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    totalEpisodes != null && totalEpisodes > 0
                        ? '$_progress / $totalEpisodes'
                        : '$_progress / -',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _progress > 0
                        ? () => setState(() => _progress--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Slider(
                      value: _progress.clamp(0, effectiveMax).toDouble(),
                      min: 0,
                      max: effectiveMax.toDouble(),
                      divisions: effectiveMax,
                      label: '$_progress',
                      onChanged: (v) => setState(() => _progress = v.round()),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed:
                        (totalEpisodes != null && _progress >= totalEpisodes)
                        ? null
                        : () => setState(() => _progress++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Score (0 - 10)', style: theme.textTheme.labelLarge),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_score/10',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Slider(
                value: _score.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: '$_score',
                onChanged: (v) => setState(() => _score = v.round()),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(mediaLibraryProvider.notifier)
                          .updateItemDetails(
                            item: widget.item,
                            status: _status,
                            score: _score,
                            progress: _progress,
                            serviceStatuses: _serviceStatusOverrides,
                            serviceProgresses: _serviceProgressOverrides,
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated "${widget.item.title}"'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Save & Sync'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
