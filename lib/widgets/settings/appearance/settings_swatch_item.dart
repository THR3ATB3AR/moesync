import 'package:flutter/material.dart';

class SettingsSwatchItem extends StatelessWidget {
  const SettingsSwatchItem({
    super.key,
    required this.context,
    required this.isSelected,
    required this.tooltip,
    required this.colors,
    this.centerIcon,
    required this.onTap,
  });

  final BuildContext context;
  final bool isSelected;
  final String tooltip;
  final List<Color> colors;
  final IconData? centerIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isSelected ? 3.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: Container(color: colors[0])),
                        Expanded(child: Container(color: colors[1])),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: Container(color: colors[2])),
                        Expanded(child: Container(color: colors[3])),
                      ],
                    ),
                  ),
                ],
              ),
              if (centerIcon != null && !isSelected)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(centerIcon, size: 16, color: Colors.white),
                  ),
                ),
              if (isSelected)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
