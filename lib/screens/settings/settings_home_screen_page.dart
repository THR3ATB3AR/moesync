import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../widgets/home/home_widget_registry.dart';

class SettingsHomeScreenPage extends ConsumerWidget {
  const SettingsHomeScreenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final settings = ref.watch(homeScreenWidgetSettingsProvider);
    final notifier = ref.read(homeScreenWidgetSettingsProvider.notifier);
    final definitions = {
      for (final definition in homeWidgetRegistry) definition.id: definition,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.homeScreen),
        actions: [
          IconButton(
            tooltip: localizations.resetHomeScreen,
            onPressed: notifier.reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              localizations.homeScreenCustomizationHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: settings.order.length,
              onReorderItem: notifier.reorder,
              itemBuilder: (context, index) {
                final id = settings.order[index];
                final definition = definitions[id];
                if (definition == null) return const SizedBox.shrink();
                return Card(
                  key: ValueKey(id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(definition.icon, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            definition.title(localizations),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        Semantics(
                          label: definition.title(localizations),
                          child: Switch(
                            value: settings.isEnabled(id),
                            onChanged: (enabled) =>
                                notifier.setEnabled(id, enabled),
                          ),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
