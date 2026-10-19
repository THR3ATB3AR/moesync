import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/oauth_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsServiceCard extends StatelessWidget {
  const SettingsServiceCard({
    super.key,
    required this.context,
    required this.ref,
    required this.service,
    required this.creds,
    required this.isConnected,
    required this.theme,
  });

  final BuildContext context;
  final WidgetRef ref;
  final ServiceType service;
  final ServiceCredentials creds;
  final bool isConnected;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final serviceErrors = ref.watch(serviceErrorsProvider);
    final hasError = isConnected && serviceErrors.containsKey(service);
    final errorMsg = serviceErrors[service];

    final Color leadingBg;
    final Color leadingIconColor;
    final IconData leadingIcon;
    final BorderSide borderSide;
    final Widget subtitleWidget;

    if (hasError) {
      leadingBg = theme.colorScheme.errorContainer;
      leadingIconColor = theme.colorScheme.error;
      leadingIcon = Icons.error_outline_rounded;
      borderSide = BorderSide(
        color: theme.colorScheme.error.withValues(alpha: 0.7),
        width: 1.2,
      );
      subtitleWidget = Text(
        'Błąd: $errorMsg',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } else if (isConnected) {
      leadingBg = theme.colorScheme.primaryContainer;
      leadingIconColor = theme.colorScheme.onPrimaryContainer;
      leadingIcon = Icons.cloud_done_rounded;
      borderSide = BorderSide(
        color: theme.colorScheme.primary.withValues(alpha: 0.3),
      );
      subtitleWidget = Text(
        creds.username != null && creds.username!.isNotEmpty
            ? 'Connected as ${creds.username}'
            : 'Connected with token',
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.green.shade700,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      leadingBg = theme.colorScheme.surfaceContainerHighest;
      leadingIconColor = theme.colorScheme.outline;
      leadingIcon = Icons.cloud_off_rounded;
      borderSide = BorderSide(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
      );
      subtitleWidget = Text(
        'Not connected (tap to configure)',
        style: theme.textTheme.bodySmall,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: borderSide,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: leadingBg,
          child: Icon(leadingIcon, color: leadingIconColor),
        ),
        title: Text(
          service.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: subtitleWidget,
        onTap: () => showDialog(
          context: context,
          builder: (_) => OAuthDialog(service: service),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isConnected) ...[
              IconButton(
                tooltip: 'Logout from ${service.displayName}',
                icon: Icon(
                  Icons.logout_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Logout from ${service.displayName}?'),
                      content: Text(
                        'Are you sure you want to disconnect ${service.displayName}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(authProvider.notifier).disconnect(service);
                    ref.read(mediaLibraryProvider.notifier).loadItems();
                    ref.read(syncProvider.notifier).scanDiffs();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✓ Logged out of ${service.displayName}',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => OAuthDialog(service: service),
              ),
              child: Text(isConnected ? 'Manage' : 'Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
