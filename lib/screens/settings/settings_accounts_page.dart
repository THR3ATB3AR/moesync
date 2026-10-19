import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/settings/accounts/settings_service_card.dart';
import 'package:moesync/widgets/settings/settings_section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsAccountsPage extends ConsumerWidget {
  const SettingsAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).accounts,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          SettingsSectionTitle(
            theme: theme,
            title: AppLocalizations.of(context).serviceAccounts,
          ),
          const SizedBox(height: 8),
          ...ServiceType.values.map((service) {
            final isConnected = auth.isConnected(service);
            final creds =
                auth.credentials[service] ?? const ServiceCredentials();
            return SettingsServiceCard(
              context: context,
              ref: ref,
              service: service,
              creds: creds,
              isConnected: isConnected,
              theme: theme,
            );
          }),
          if (auth.connectedCount > 0) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                AppLocalizations.of(
                  context,
                ).logoutFromAllServicesCount(auth.connectedCount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      AppLocalizations.of(context).logoutFromAllServices,
                    ),
                    content: Text(
                      AppLocalizations.of(
                        context,
                      ).areYouSureYouWantToDisconnectAllConnectedServiceAccounts,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(AppLocalizations.of(context).cancel),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(AppLocalizations.of(context).logOut),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authProvider.notifier).disconnectAll();
                  ref.read(mediaLibraryProvider.notifier).loadItems();
                  ref.read(syncProvider.notifier).scanDiffs();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context).loggedOutOfAllServices,
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
