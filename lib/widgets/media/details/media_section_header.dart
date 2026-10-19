import 'package:flutter/material.dart';

class MediaSectionHeader extends StatelessWidget {
  const MediaSectionHeader({
    super.key,
    required this.theme,
    required this.title,
    this.icon,
  });

  final ThemeData theme;
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: theme.colorScheme.primary),
        ],
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
