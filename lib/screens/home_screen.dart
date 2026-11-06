import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/home/home_widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/media_item.dart';
import '../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final library = ref.watch(mediaLibraryProvider);
    final sync = ref.watch(syncProvider);
    final widgetSettings = ref.watch(homeScreenWidgetSettingsProvider);

    final watchingAnime = library.unifiedItems
        .where(
          (u) =>
              u.mediaType == MediaType.anime &&
              u.services.values.any((s) => s.status == 'watching'),
        )
        .toList();

    final readingManga = library.unifiedItems
        .where(
          (u) =>
              u.mediaType == MediaType.manga &&
              u.services.values.any((s) => s.status == 'watching'),
        )
        .toList();

    final completedCount = library.unifiedItems
        .where((u) => u.services.values.any((s) => s.status == 'completed'))
        .length;
    final widgetData = HomeWidgetData(
      context: context,
      ref: ref,
      theme: theme,
      auth: auth,
      sync: sync,
      watchingAnime: watchingAnime,
      readingManga: readingManga,
      completedCount: completedCount,
    );
    final widgetsById = {
      for (final definition in homeWidgetRegistry) definition.id: definition,
    };

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/icon/png/moesync-icon-mono.png',
                width: 50,
                height: 50,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MoeSync',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).allInOneUnifiedAnimeManga,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).refreshLibrary,
            onPressed: () {
              ref.read(mediaLibraryProvider.notifier).loadItems();
              ref.read(syncProvider.notifier).scanDiffs();
            },
            icon: library.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).settingsAccounts,
            onPressed: () => context.push('/more/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(mediaLibraryProvider.notifier)
              .loadItems(forceRefresh: true);
          await ref.read(syncProvider.notifier).scanDiffs(forceRefresh: true);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            TextField(
              readOnly: true,
              onTap: () => context.push('/search'),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchMediaHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: const Icon(Icons.arrow_forward_rounded),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            for (final id in widgetSettings.order)
              if (widgetSettings.isEnabled(id) && widgetsById.containsKey(id))
                if (widgetsById[id]!.isVisible?.call(widgetData) ?? true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: widgetsById[id]!.builder(widgetData),
                  ),
          ],
        ),
      ),
    );
  }
}
