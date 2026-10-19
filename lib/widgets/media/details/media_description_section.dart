import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/media/details/media_section_header.dart';
import 'package:moesync/widgets/service_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaDescriptionSection extends ConsumerStatefulWidget {
  final UnifiedMediaItem item;
  final Map<ServiceType, MediaDetailData> allServiceData;
  final ServiceType selectedService;
  final MediaDetailData? detailData;
  final ThemeData theme;

  const MediaDescriptionSection({
    super.key,
    required this.item,
    required this.allServiceData,
    required this.selectedService,
    required this.detailData,
    required this.theme,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MediaDescriptionSectionState();
}

class _MediaDescriptionSectionState
    extends ConsumerState<MediaDescriptionSection> {
  late bool _isDescriptionExpanded;
  late int _currentDescPage;
  late PageController _descPageController;

  @override
  void initState() {
    super.initState();
    _descPageController = PageController();
    _isDescriptionExpanded = false;
    _currentDescPage = 0;
  }

  String _normalizeDescription(String raw) {
    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return normalized.replaceAll(RegExp(r'\n\s*\n+'), '\n').trim();
  }

  static const int _defaultCollapsedMaxLines = 5;

  double _calculateDescriptionCardHeight({
    required String text,
    required double maxWidth,
    required TextStyle textStyle,
    required TextScaler textScaler,
    required bool isExpanded,
    required bool isTooLong,
  }) {
    const chromeHeight = 72.0;
    if (text.isEmpty) return 90.0;

    try {
      final textWidth = (maxWidth - 36.0).clamp(100.0, 2000.0);
      if (!isTooLong || isExpanded) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout(maxWidth: textWidth);
        return (tp.size.height + chromeHeight).ceilToDouble();
      } else {
        final tp = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
          maxLines: _defaultCollapsedMaxLines,
        )..layout(maxWidth: textWidth);
        return (tp.size.height + chromeHeight)
            .clamp(90.0, 165.0)
            .ceilToDouble();
      }
    } catch (_) {
      return isExpanded ? 340.0 : 165.0;
    }
  }

  bool _isDescriptionTooLong({
    required String text,
    required double maxWidth,
    required TextStyle textStyle,
    required TextScaler textScaler,
  }) {
    if (text.isEmpty) return false;
    final newlineCount = '\n'.allMatches(text).length;
    if (newlineCount >= _defaultCollapsedMaxLines) return true;
    if (text.length > 280) return true;

    try {
      final textWidth = (maxWidth - 36.0).clamp(100.0, 2000.0);
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: _defaultCollapsedMaxLines,
      )..layout(maxWidth: textWidth);
      return tp.didExceedMaxLines;
    } catch (_) {
      return text.length > 200;
    }
  }

  List<MapEntry<ServiceType, String>> _getAvailableDescriptions() {
    final list = <MapEntry<ServiceType, String>>[];
    final preferredDesc = ref
        .read(storageServiceProvider)
        .getDefaultDescriptionSource(widget.item.mediaType);
    final effectiveFirst = preferredDesc ?? widget.selectedService;

    if (widget.allServiceData.containsKey(effectiveFirst)) {
      final desc = widget.allServiceData[effectiveFirst]?.description;
      if (desc != null && desc.trim().isNotEmpty) {
        list.add(MapEntry(effectiveFirst, _normalizeDescription(desc)));
      }
    }

    if (effectiveFirst != ServiceType.mal &&
        widget.allServiceData.containsKey(ServiceType.mal)) {
      final desc = widget.allServiceData[ServiceType.mal]?.description;
      if (desc != null && desc.trim().isNotEmpty) {
        list.add(MapEntry(ServiceType.mal, _normalizeDescription(desc)));
      }
    }

    for (final entry in widget.allServiceData.entries) {
      if (entry.key == effectiveFirst || entry.key == ServiceType.mal) continue;
      final desc = entry.value.description;
      if (desc != null && desc.trim().isNotEmpty) {
        list.add(MapEntry(entry.key, _normalizeDescription(desc)));
      }
    }

    if (list.isEmpty &&
        widget.detailData?.description != null &&
        widget.detailData!.description!.trim().isNotEmpty) {
      list.add(
        MapEntry(
          widget.selectedService,
          _normalizeDescription(widget.detailData!.description!),
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final descriptions = _getAvailableDescriptions();
    if (descriptions.isEmpty) return const SizedBox.shrink();
    if (_currentDescPage >= descriptions.length) {
      _currentDescPage = 0;
    }

    final textStyle =
        widget.theme.textTheme.bodyMedium?.copyWith(height: 1.45) ??
        const TextStyle(fontSize: 14, height: 1.45);
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenWidth = mediaQuery?.size.width ?? 400.0;
    final textScaler = mediaQuery?.textScaler ?? TextScaler.noScaling;
    final availableWidth = (screenWidth - 32.0).clamp(100.0, 2000.0);

    final currentDesc = descriptions[_currentDescPage].value;
    final isTooLong = _isDescriptionTooLong(
      text: currentDesc,
      maxWidth: availableWidth,
      textStyle: textStyle,
      textScaler: textScaler,
    );
    final isExpanded = _isDescriptionExpanded && isTooLong;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MediaSectionHeader(
                theme: widget.theme,
                title: AppLocalizations.of(context).descriptionSummary,
                icon: Icons.description_rounded,
              ),
              const Spacer(),
              if (descriptions.length > 1)
                Text(
                  AppLocalizations.of(
                    context,
                  ).swipeHorizontallyDescriptionsCount(
                    _currentDescPage + 1,
                    descriptions.length,
                  ),
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    color: widget.theme.colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (descriptions.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: descriptions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final svc = entry.value.key;
                  final isCurrent = idx == _currentDescPage;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isCurrent,
                      avatar: ServiceBadgeChip(service: svc, size: 14),
                      label: Text(
                        svc.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() => _currentDescPage = idx);
                        _descPageController.animateToPage(
                          idx,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],

          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: _calculateDescriptionCardHeight(
              text: currentDesc,
              maxWidth: availableWidth,
              textStyle: textStyle,
              textScaler: textScaler,
              isExpanded: isExpanded,
              isTooLong: isTooLong,
            ),
            child: PageView.builder(
              controller: _descPageController,
              itemCount: descriptions.length,
              onPageChanged: (idx) {
                setState(() => _currentDescPage = idx);
              },
              itemBuilder: (context, index) {
                final entry = descriptions[index];
                final service = entry.key;
                final descText = entry.value;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(
                      () => _isDescriptionExpanded = !_isDescriptionExpanded,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(14),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 28,
                          child: Row(
                            children: [
                              ServiceBadgeChip(service: service, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).descriptionFromService(service.displayName),
                                style: widget.theme.textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme.colorScheme.primary,
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                visualDensity: VisualDensity.compact,
                                tooltip: AppLocalizations.of(context)
                                    .copyDescriptionFromService(
                                      service.displayName,
                                    ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: descText),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).descriptionFromServiceCopiedToClipboard(
                                          service.displayName,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Text(
                              descText,
                              style: textStyle.copyWith(
                                color: widget.theme.colorScheme.onSurface
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (descriptions.length > 1 || isTooLong) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    descriptions.length > 1
                        ? AppLocalizations.of(
                            context,
                          ).swipeLeftRightToCompareDescriptions
                        : '',
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      color: widget.theme.colorScheme.outline,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (isTooLong)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    icon: Icon(
                      _isDescriptionExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _isDescriptionExpanded
                          ? AppLocalizations.of(context).shrinkDescription
                          : AppLocalizations.of(context).expandDescription,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
