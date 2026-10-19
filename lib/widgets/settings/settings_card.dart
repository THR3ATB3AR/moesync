import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsCard extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? content;
  const SettingsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.content,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsCardState();
}

class _SettingsCardState extends ConsumerState<SettingsCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            widget.content != null
                ? const SizedBox(height: 16)
                : const SizedBox.shrink(),
            widget.content != null
                ? SizedBox(width: double.infinity, child: widget.content)
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
