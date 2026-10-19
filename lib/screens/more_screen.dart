import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../widgets/service_errors_dialog.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final library = ref.watch(mediaLibraryProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 28, bottom: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.35,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.45,
                          ),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icon/png/moesync-icon-mono.png',
                          width: 64,
                          height: 64,
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.primary,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'MoeSync',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 6),

            if (library.serviceErrors.isNotEmpty) ...[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 26,
                ),
                title: Text(
                  AppLocalizations.of(
                    context,
                  ).detectedServiceErrors(library.serviceErrors.length),
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  ).tapToViewDetailsOrRetryOperations,
                ),
                onTap: () {
                  ServiceErrorsDialog.show(
                    context,
                    errors: library.serviceErrors,
                    onRetry: () =>
                        ref.read(mediaLibraryProvider.notifier).loadItems(),
                  );
                },
              ),
            ],
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: Icon(
                Icons.settings_outlined,
                color: theme.colorScheme.primary,
                size: 26,
              ),
              title: Text(
                AppLocalizations.of(context).settings,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(context).appearanceTrackingAccounts,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {
                context.push('/more/settings');
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: Icon(
                Icons.storage_rounded,
                color: theme.colorScheme.primary,
                size: 26,
              ),
              title: Text(
                AppLocalizations.of(context).sourcesDatabase,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                ).defaultSourceForInformationDescriptionAndSynchronization,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {
                context.push('/more/settings/sources');
              },
            ),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 26,
              ),
              title: Text(
                AppLocalizations.of(context).about,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(context).moesyncNewestReleasesAndMore,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {
                context.push('/more/settings/about');
              },
            ),
          ],
        ),
      ),
    );
  }
}
