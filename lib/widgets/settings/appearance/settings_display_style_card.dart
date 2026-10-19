import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/service_badge.dart';
import 'package:moesync/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsDisplayStyleCard extends StatelessWidget {
  const SettingsDisplayStyleCard({
    super.key,
    required this.context,
    required this.ref,
    required this.theme,
  });

  final BuildContext context;
  final WidgetRef ref;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final currentStyle = ref.watch(serviceDisplayStyleProvider);

    return SettingsCard(
      icon: Icons.style_rounded,
      title: "Display style",
      subtitle: 'Set display style for anime and manga collections',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ServiceDisplayStyle>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ServiceDisplayStyle.text,
                  icon: Icon(Icons.title_rounded, size: 16),
                  label: Text('Text'),
                ),
                ButtonSegment(
                  value: ServiceDisplayStyle.icon,
                  icon: Icon(Icons.palette_outlined, size: 16),
                  label: Text('Icon'),
                ),
                ButtonSegment(
                  value: ServiceDisplayStyle.monoIcon,
                  icon: Icon(Icons.contrast_rounded, size: 16),
                  label: Text('Mono Icon'),
                ),
              ],
              selected: {currentStyle},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  ref
                      .read(serviceDisplayStyleProvider.notifier)
                      .setStyle(set.first);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Preview:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: ServiceType.values.map((s) {
                    return ServiceBadgeChip(
                      service: s,
                      size: 18,
                      compact: false,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
