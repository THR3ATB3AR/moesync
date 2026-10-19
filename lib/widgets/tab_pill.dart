import 'package:flutter/material.dart';

class TabPill extends StatefulWidget {
  final IconData icon;
  final int index;
  final String tooltip;
  final ThemeData theme;
  final int activeTab;
  final ValueChanged<int> onTap;

  const TabPill({
    super.key,
    required this.icon,
    required this.index,
    required this.tooltip,
    required this.theme,
    required this.activeTab,
    required this.onTap,
  });

  @override
  State<TabPill> createState() => _TabPillState();
}

class _TabPillState extends State<TabPill> {
  @override
  Widget build(BuildContext context) {
    final isSelected = widget.activeTab == widget.index;
    return Tooltip(
      message: widget.tooltip,
      child: InkWell(
        onTap: () => widget.onTap(widget.index),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? widget.theme.colorScheme.primaryContainer
                : widget.theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: widget.theme.brightness == Brightness.light
                        ? 0.6
                        : 0.4,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? widget.theme.colorScheme.primary
                  : widget.theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 22,
              color: isSelected
                  ? widget.theme.colorScheme.onPrimaryContainer
                  : widget.theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
