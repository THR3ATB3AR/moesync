import 'package:flutter/material.dart';
import '../../models/media_item.dart';

class MediaSortDialog extends StatefulWidget {
  final MediaSortField currentField;
  final SortDirection currentDirection;
  final void Function(MediaSortField field, SortDirection direction)
  onSortChanged;

  const MediaSortDialog({
    super.key,
    required this.currentField,
    required this.currentDirection,
    required this.onSortChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required MediaSortField currentField,
    required SortDirection currentDirection,
    required void Function(MediaSortField field, SortDirection direction)
    onSortChanged,
    Offset? anchorOffset,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) {
        return MediaSortDialog(
          currentField: currentField,
          currentDirection: currentDirection,
          onSortChanged: onSortChanged,
        );
      },
    );
  }

  @override
  State<MediaSortDialog> createState() => _MediaSortDialogState();
}

class _MediaSortDialogState extends State<MediaSortDialog> {
  late MediaSortField _selectedField;
  late SortDirection _selectedDirection;

  @override
  void initState() {
    super.initState();
    _selectedField = widget.currentField;
    _selectedDirection = widget.currentDirection;
  }

  void _onItemTapped(MediaSortField field) {
    if (_selectedField == field) {
      final newDir = _selectedDirection == SortDirection.descending
          ? SortDirection.ascending
          : SortDirection.descending;
      setState(() {
        _selectedDirection = newDir;
      });
      widget.onSortChanged(field, newDir);
    } else {
      final defaultDir = field == MediaSortField.title
          ? SortDirection.ascending
          : SortDirection.descending;
      setState(() {
        _selectedField = field;
        _selectedDirection = defaultDir;
      });
      widget.onSortChanged(field, defaultDir);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.only(top: 80, right: 16, bottom: 24),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(width: 1.2),
        ),
        elevation: 12,
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 250,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: MediaSortField.values.map((field) {
              final isSelected = field == _selectedField;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: isSelected
                    ? _buildActiveItem(field)
                    : _buildInactiveItem(field),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveItem(MediaSortField field) {
    return InkWell(
      onTap: () => _onItemTapped(field),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(blurRadius: 10, offset: const Offset(0, 2))],
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _selectedDirection == SortDirection.descending
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                field.getLabel(context),
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveItem(MediaSortField field) {
    return InkWell(
      onTap: () => _onItemTapped(field),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.centerLeft,
        child: Text(
          field.getLabel(context),
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
