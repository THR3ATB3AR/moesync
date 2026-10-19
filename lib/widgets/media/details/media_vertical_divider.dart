import 'package:flutter/material.dart';

class MediaVerticalDivider extends StatelessWidget {
  const MediaVerticalDivider({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
    );
  }
}
