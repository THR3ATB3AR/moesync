import 'package:moesync/models/media_detail_data.dart';
import 'package:flutter/material.dart';

class MediaDistPill extends StatelessWidget {
  const MediaDistPill({
    super.key,
    required this.theme,
    required this.label,
    required this.value,
    required this.color,
  });

  final ThemeData theme;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${formatNumber(value)}  $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
