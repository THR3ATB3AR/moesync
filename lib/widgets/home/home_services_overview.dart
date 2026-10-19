import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/oauth_dialog.dart';
import 'package:moesync/widgets/service_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeServicesOverview extends StatelessWidget {
  const HomeServicesOverview({
    super.key,
    required this.context,
    required this.ref,
    required this.auth,
    required this.theme,
  });

  final BuildContext context;
  final WidgetRef ref;
  final AuthState auth;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).connectedServices,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/more/settings/accounts'),
              child: Text(AppLocalizations.of(context).manage),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ServiceType.values.map((s) {
              final connected = auth.isConnected(s);
              final serviceErrors = ref.watch(serviceErrorsProvider);
              final hasError = connected && serviceErrors.containsKey(s);
              final errorMsg = serviceErrors[s];

              final Color dotColor;
              final Color borderColor;
              final Color bgColor;
              final Color textColor;

              if (hasError) {
                dotColor = theme.colorScheme.error;
                borderColor = theme.colorScheme.error.withValues(alpha: 0.8);
                bgColor = theme.colorScheme.errorContainer.withValues(
                  alpha: 0.35,
                );
                textColor = theme.colorScheme.error;
              } else if (connected) {
                dotColor = Colors.green;
                borderColor = theme.colorScheme.secondary;
                bgColor = theme.colorScheme.secondaryContainer;
                textColor = theme.colorScheme.onSecondaryContainer;
              } else {
                dotColor = Colors.grey;
                borderColor = Colors.transparent;
                bgColor = theme.colorScheme.surfaceContainerHighest;
                textColor = theme.colorScheme.onSurfaceVariant;
              }

              return Tooltip(
                message: hasError
                    ? '${s.displayName}: $errorMsg'
                    : (connected
                          ? AppLocalizations.of(
                              context,
                            ).serviceConnected(s.displayName)
                          : AppLocalizations.of(
                              context,
                            ).serviceNotConnected(s.displayName)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => OAuthDialog(service: s),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasError)
                          Icon(
                            Icons.error_outline_rounded,
                            size: 12,
                            color: dotColor,
                          )
                        else
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                            ),
                          ),
                        const SizedBox(width: 8),
                        ServiceBadge(
                          service: s,
                          size: 16,
                          showLabelWithIcon: true,
                          textStyle: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
