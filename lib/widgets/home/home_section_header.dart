import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.context,
    required this.title,
    required this.icon,
    required this.onViewAll,
  });

  final BuildContext context;
  final String title;
  final IconData icon;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onViewAll,
          child: Text(AppLocalizations.of(context).viewAll),
        ),
      ],
    );
  }
}
