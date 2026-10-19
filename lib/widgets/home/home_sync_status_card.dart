import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeSyncStatusCard extends StatelessWidget {
  const HomeSyncStatusCard({
    super.key,
    required this.context,
    required this.ref,
    required this.sync,
    required this.auth,
    required this.theme,
  });

  final BuildContext context;
  final WidgetRef ref;
  final SyncState sync;
  final AuthState auth;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final pendingCount = sync.pendingActions.length;
    final isSyncing = sync.isSyncing;
    final isAnyConnected = auth.connectedCount > 0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    !isAnyConnected
                        ? Icons.cloud_off_rounded
                        : (isSyncing
                              ? Icons.sync
                              : (pendingCount > 0
                                    ? Icons.difference_rounded
                                    : Icons.check_circle_rounded)),
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !isAnyConnected
                            ? AppLocalizations.of(context).noAccountsConnected
                            : (pendingCount > 0
                                  ? AppLocalizations.of(
                                      context,
                                    ).pendingcountPendingUpdates
                                  : AppLocalizations.of(
                                      context,
                                    ).listsFullySynchronized),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !isAnyConnected
                            ? AppLocalizations.of(
                                context,
                              ).connectYourListServicesInSettingsToStartSynchronizing
                            : (pendingCount > 0
                                  ? AppLocalizations.of(
                                      context,
                                    ).differencesDetectedAgainstPrimaryservice(
                                      sync.primaryService.displayName,
                                    )
                                  : AppLocalizations.of(
                                      context,
                                    ).allYourConnectedServicesAreUpToDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isAnyConnected)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/more/settings/accounts'),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(
                    AppLocalizations.of(context).connectAccountsInSettings,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.go('/sync'),
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: Text(AppLocalizations.of(context).reviewDiffs),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: pendingCount > 0 && !isSyncing
                          ? () => ref.read(syncProvider.notifier).executeSync()
                          : () => ref.read(syncProvider.notifier).scanDiffs(),
                      icon: Icon(
                        pendingCount > 0 ? Icons.sync_rounded : Icons.search,
                        size: 18,
                      ),
                      label: Text(
                        pendingCount > 0
                            ? AppLocalizations.of(context).syncAll
                            : AppLocalizations.of(context).scanLists,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
