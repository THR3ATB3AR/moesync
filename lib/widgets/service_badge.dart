import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/media_item.dart';
import '../providers/providers.dart';

class ServiceBadge extends ConsumerWidget {
  final ServiceType service;
  final double size;
  final TextStyle? textStyle;
  final ServiceDisplayStyle? styleOverride;
  final bool compact;
  final bool showLabelWithIcon;
  final Color? color;

  const ServiceBadge({
    super.key,
    required this.service,
    this.size = 16,
    this.textStyle,
    this.styleOverride,
    this.compact = false,
    this.showLabelWithIcon = false,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ServiceDisplayStyle displayStyle =
        styleOverride ?? ref.watch(serviceDisplayStyleProvider);
    final effectiveColor = color ?? theme.colorScheme.primary;

    switch (displayStyle) {
      case ServiceDisplayStyle.text:
        return Text(
          compact ? service.shortName : service.displayName,
          style: textStyle,
        );

      case ServiceDisplayStyle.icon:
        final iconWidget = SvgPicture.asset(
          service.iconAsset,
          width: size,
          height: size,
        );
        if (!showLabelWithIcon) {
          return Tooltip(
            message: service.displayName,
            child: iconWidget,
          );
        }
        return Tooltip(
          message: service.displayName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: 6),
              Text(
                compact ? service.shortName : service.displayName,
                style: textStyle,
              ),
            ],
          ),
        );

      case ServiceDisplayStyle.monoIcon:
        final monoWidget = SvgPicture.asset(
          service.monoIconAsset,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
        );
        if (!showLabelWithIcon) {
          return Tooltip(
            message: service.displayName,
            child: monoWidget,
          );
        }
        return Tooltip(
          message: service.displayName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              monoWidget,
              const SizedBox(width: 6),
              Text(
                compact ? service.shortName : service.displayName,
                style: textStyle,
              ),
            ],
          ),
        );
    }
  }
}

class ServiceBadgeChip extends ConsumerWidget {
  final ServiceType service;
  final double size;
  final bool compact;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final ServiceDisplayStyle? styleOverride;

  const ServiceBadgeChip({
    super.key,
    required this.service,
    this.size = 14,
    this.compact = true,
    this.padding,
    this.onTap,
    this.styleOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final displayStyle =
        styleOverride ?? ref.watch(serviceDisplayStyleProvider);

    final chipPadding = padding ??
        (displayStyle == ServiceDisplayStyle.text
            ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
            : const EdgeInsets.all(4));

    final child = Container(
      padding: chipPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: ServiceBadge(
        service: service,
        size: size,
        compact: compact,
        styleOverride: styleOverride,
        textStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: child,
      );
    }
    return child;
  }
}
