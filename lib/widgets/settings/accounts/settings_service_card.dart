import 'package:moesync/models/media_item.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
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
        l.serviceErrorMessage(errorMsg ?? ''),
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
            ? l.connectedAsUser(creds.username!)
            : l.connectedWithToken,
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
        l.notConnectedTapToConfigure,
        style: theme.textTheme.bodySmall,
      );
    }

    Future<void> disconnectService() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.logoutFromServiceQuestion(service.displayName)),
          content: Text(l.confirmDisconnectService(service.displayName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.logoutService(service.displayName)),
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
              content: Text(l.loggedOutFromService(service.displayName)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    void openConnectionDialog() => showDialog(
      context: context,
      builder: (_) => OAuthDialog(service: service),
    );

    Widget connectButton({bool expanded = false}) {
      final button = OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: openConnectionDialog,
        child: Text(
          isConnected ? l.manage : l.connectService(service.displayName),
          textAlign: TextAlign.center,
        ),
      );
      return expanded
          ? SizedBox(width: double.infinity, child: button)
          : button;
    }

    Widget logoutButton() => IconButton(
      tooltip: l.logoutFromServiceTooltip(service.displayName),
      icon: Icon(
        Icons.logout_rounded,
        color: theme.colorScheme.error,
        size: 20,
      ),
      onPressed: disconnectService,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: borderSide,
          ),
          child: compact
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: openConnectionDialog,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: leadingBg,
                              child: Icon(leadingIcon, color: leadingIconColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  subtitleWidget,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (isConnected) logoutButton(),
                          Expanded(child: connectButton(expanded: true)),
                        ],
                      ),
                    ],
                  ),
                )
              : ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: leadingBg,
                    child: Icon(leadingIcon, color: leadingIconColor),
                  ),
                  title: Text(
                    service.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: subtitleWidget,
                  onTap: openConnectionDialog,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isConnected) ...[
                        logoutButton(),
                        const SizedBox(width: 4),
                      ],
                      connectButton(),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
