import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/widgets/skeleton_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/media_item.dart';
import '../providers/providers.dart';
import '../widgets/service_badge.dart';
import '../widgets/service_errors_dialog.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _actionTypeFilter = 'all';
  ServiceType? _targetServiceFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final sync = ref.watch(syncProvider);
    final notifier = ref.read(syncProvider.notifier);

    final filteredActions = sync.pendingActions.where((a) {
      if (_searchQuery.isNotEmpty &&
          !a.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_targetServiceFilter != null &&
          a.targetService != _targetServiceFilter) {
        return false;
      }
      if (_actionTypeFilter == 'add' && !a.isAdd) {
        return false;
      }
      if (_actionTypeFilter == 'update' && a.isAdd) {
        return false;
      }
      return true;
    }).toList();

    final addActions = filteredActions.where((a) => a.isAdd).toList();
    final updateActions = filteredActions.where((a) => !a.isAdd).toList();
    final selectedCount = sync.pendingActions.where((a) => a.isSelected).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).listSynchronization,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (sync.serviceErrors.isNotEmpty)
            IconButton(
              tooltip: AppLocalizations.of(
                context,
              ).detectedServiceErrors(sync.serviceErrors.length),
              icon: Badge(
                label: Text('${sync.serviceErrors.length}'),
                backgroundColor: theme.colorScheme.error,
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                ),
              ),
              onPressed: () {
                ServiceErrorsDialog.show(
                  context,
                  errors: sync.serviceErrors,
                  onRetry: () => notifier.scanDiffs(),
                );
              },
            ),
          IconButton(
            tooltip: AppLocalizations.of(context).rescanDifferences,
            onPressed: sync.isScanning || sync.isSyncing
                ? null
                : () => notifier.scanDiffs(),
            icon: sync.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_outline_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).primarySourceOfTruth,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<ServiceType>(
                            key: ValueKey(
                              'primary_${sync.primaryService.name}_${sync.mediaType.name}',
                            ),
                            initialValue:
                                ServiceType.forMediaType(
                                  sync.mediaType,
                                ).contains(sync.primaryService)
                                ? sync.primaryService
                                : ServiceType.forMediaType(
                                    sync.mediaType,
                                  ).first,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ServiceType.forMediaType(sync.mediaType).map(
                              (s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ServiceBadge(service: s, size: 18),
                                      const SizedBox(width: 8),
                                      Text(s.displayName),
                                    ],
                                  ),
                                );
                              },
                            ).toList(),
                            onChanged: (val) {
                              if (val != null) notifier.setPrimary(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: SegmentedButton<MediaType>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: MediaType.anime,
                                label: Text(AppLocalizations.of(context).anime),
                              ),
                              ButtonSegment(
                                value: MediaType.manga,
                                label: Text(AppLocalizations.of(context).manga),
                              ),
                            ],
                            selected: {sync.mediaType},
                            onSelectionChanged: (set) {
                              if (set.isNotEmpty) {
                                notifier.setMediaType(set.first);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (!sync.isScanning &&
              !sync.isSyncing &&
              sync.pendingActions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        ).searchPendingSyncTitles,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: AppLocalizations.of(context).filterByTargetService,
                    initialValue: _targetServiceFilter?.name ?? 'all',
                    onSelected: (val) {
                      setState(() {
                        if (val == 'all') {
                          _targetServiceFilter = null;
                        } else {
                          _targetServiceFilter = ServiceType.values.firstWhere(
                            (s) => s.name == val,
                          );
                        }
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'all',
                        child: Text(AppLocalizations.of(context).allTargets),
                      ),
                      const PopupMenuDivider(),
                      ...ServiceType.values.map(
                        (s) => PopupMenuItem(
                          value: s.name,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ServiceBadge(service: s, size: 18),
                              const SizedBox(width: 8),
                              Text(s.displayName),
                            ],
                          ),
                        ),
                      ),
                    ],
                    child: Chip(
                      avatar: _targetServiceFilter != null
                          ? ServiceBadge(
                              service: _targetServiceFilter!,
                              size: 16,
                              compact: true,
                            )
                          : Icon(
                              Icons.filter_list_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                      label: Text(
                        _targetServiceFilter != null
                            ? _targetServiceFilter!.displayName
                            : AppLocalizations.of(context).allTargets,
                      ),
                      onDeleted: _targetServiceFilter != null
                          ? () => setState(() => _targetServiceFilter = null)
                          : null,
                      backgroundColor: _targetServiceFilter != null
                          ? theme.colorScheme.primaryContainer
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(
                        '${AppLocalizations.of(context).all} (${sync.pendingActions.length})',
                      ),
                      selected: _actionTypeFilter == 'all',
                      onSelected: (selected) {
                        if (selected) setState(() => _actionTypeFilter = 'all');
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(
                        AppLocalizations.of(context).toAddCountActions(
                          sync.pendingActions.where((a) => a.isAdd).length,
                        ),
                      ),
                      selected: _actionTypeFilter == 'add',
                      selectedColor: Colors.green.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        if (selected) setState(() => _actionTypeFilter = 'add');
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(
                        AppLocalizations.of(context).toUpdateCountActions(
                          sync.pendingActions.where((a) => !a.isAdd).length,
                        ),
                      ),
                      selected: _actionTypeFilter == 'update',
                      selectedColor: Colors.amber.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _actionTypeFilter = 'update');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (!sync.isScanning &&
              !sync.isSyncing &&
              sync.pendingActions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    filteredActions.length < sync.pendingActions.length
                        ? AppLocalizations.of(
                            context,
                          ).filteredCountOfSyncPendingActions(
                            filteredActions.length,
                            sync.pendingActions.length,
                          )
                        : AppLocalizations.of(
                            context,
                          ).pendingActionsCount(sync.pendingActions.length),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      if (filteredActions.length < sync.pendingActions.length) {
                        for (final a in filteredActions) {
                          final idx = sync.pendingActions.indexOf(a);
                          if (idx != -1 && !a.isSelected) {
                            notifier.toggleAction(idx);
                          }
                        }
                      } else {
                        notifier.selectAll(true);
                      }
                    },
                    child: Text(
                      filteredActions.length < sync.pendingActions.length
                          ? AppLocalizations.of(context).selectFiltered
                          : AppLocalizations.of(context).selectAll,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (filteredActions.length < sync.pendingActions.length) {
                        for (final a in filteredActions) {
                          final idx = sync.pendingActions.indexOf(a);
                          if (idx != -1 && a.isSelected) {
                            notifier.toggleAction(idx);
                          }
                        }
                      } else {
                        notifier.selectAll(false);
                      }
                    },
                    child: Text(AppLocalizations.of(context).none),
                  ),
                ],
              ),
            ),
          Expanded(
            child: sync.isScanning
                ? SyncScreenSkeleton()
                : RefreshIndicator(
                    onRefresh: () async {
                      await notifier.scanDiffs(forceRefresh: true);
                    },
                    child: auth.connectedCount < 2
                        ? LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.sync_disabled_rounded,
                                      size: 64,
                                      color: theme.colorScheme.outline,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      auth.connectedCount == 0
                                          ? AppLocalizations.of(
                                              context,
                                            ).noAccountsConnected
                                          : AppLocalizations.of(
                                              context,
                                            ).connectAtLeast2Services,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      auth.connectedCount == 0
                                          ? AppLocalizations.of(
                                              context,
                                            ).connectYourListAccountsInSettingsToStartSynchronizingAnimeAndManga
                                          : AppLocalizations.of(
                                              context,
                                            ).connectAtLeastOneMoreServiceInSettingsToCompareAndSyncYourLists,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 20),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          context.push('/more/settings'),
                                      icon: const Icon(
                                        Icons.tune_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).goToSettings,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : sync.pendingActions.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 64,
                                          color: Colors.green.shade600,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          ).everythingIsInSync,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          ).noDifferencesDetectedWithPrimaryservice(
                                            sync.primaryService.displayName,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          )
                        : filteredActions.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.filter_alt_off_rounded,
                                          size: 48,
                                          color: theme.colorScheme.outline,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          ).noActionsMatchActiveFilters,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                              _actionTypeFilter = 'all';
                                              _targetServiceFilter = null;
                                            });
                                          },
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            ).resetFilters,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (addActions.isNotEmpty) ...[
                                SyncGroupHeader(
                                  theme: theme,
                                  title: AppLocalizations.of(
                                    context,
                                  ).toAddCountActions(addActions.length),
                                  color: Colors.green.shade700,
                                ),
                                ...addActions.map((action) {
                                  final originalIndex = sync.pendingActions
                                      .indexOf(action);
                                  return SyncActionTitle(
                                    context: context,
                                    ref: ref,
                                    action: action,
                                    index: originalIndex,
                                    theme: theme,
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                              if (updateActions.isNotEmpty) ...[
                                SyncGroupHeader(
                                  theme: theme,
                                  title: AppLocalizations.of(
                                    context,
                                  ).toUpdateCountActions(updateActions.length),
                                  color: Colors.amber.shade800,
                                ),
                                ...updateActions.map((action) {
                                  final originalIndex = sync.pendingActions
                                      .indexOf(action);
                                  return SyncActionTitle(
                                    context: context,
                                    ref: ref,
                                    action: action,
                                    index: originalIndex,
                                    theme: theme,
                                  );
                                }),
                              ],
                              const SizedBox(height: 80),
                            ],
                          ),
                  ),
          ),
          if (sync.isSyncing)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surfaceContainerHigh,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        ).applyingChangesSyncCountSyncTotalToSync(
                          sync.syncedCount,
                          sync.totalToSync,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: sync.totalToSync > 0
                        ? sync.syncedCount / sync.totalToSync
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          (sync.pendingActions.isNotEmpty || sync.isScanning || sync.isSyncing)
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      (!sync.isScanning && !sync.isSyncing && selectedCount > 0)
                      ? () => notifier.executeSync()
                      : null,
                  icon: (sync.isScanning || sync.isSyncing)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(
                    sync.isSyncing
                        ? AppLocalizations.of(context).syncingInProgress
                        : sync.isScanning
                        ? AppLocalizations.of(context).scanningDifferences
                        : AppLocalizations.of(
                            context,
                          ).applyChangesToTargetServices(selectedCount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class SyncGroupHeader extends StatelessWidget {
  const SyncGroupHeader({
    super.key,
    required this.theme,
    required this.title,
    required this.color,
  });

  final ThemeData theme;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedSyncStatus(String status, AppLocalizations l) {
  return switch (status.toLowerCase().replaceAll(' ', '_')) {
    'watching' => l.watching,
    'reading' => l.reading,
    'completed' => l.completed,
    'on_hold' => l.onHold,
    'dropped' => l.dropped,
    'plan_to_watch' => l.planToWatch,
    'plan_to_read' => l.planToRead,
    _ => status,
  };
}

class SyncActionTitle extends StatelessWidget {
  const SyncActionTitle({
    super.key,
    required this.context,
    required this.ref,
    required this.action,
    required this.index,
    required this.theme,
  });

  final BuildContext context;
  final WidgetRef ref;
  final SyncAction action;
  final int index;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(syncProvider.notifier);

    return InkWell(
      onTap: () => notifier.toggleAction(index),
      borderRadius: BorderRadius.circular(14),
      onLongPress: () {
        final mediaItem = resolveMediaItem(
          id: action.targetId,
          title: action.title,
          mediaType: action.mediaType,
          ref: ref,
        );
        if (context.mounted) {
          context.push('/mediaDetails', extra: mediaItem);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: action.isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: CheckboxListTile(
          value: action.isSelected,
          onChanged: (_) => notifier.toggleAction(index),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          secondary: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: action.posterImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: action.posterImage,
                    width: 44,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 60,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.movie),
                  ),
          ),
          title: Text(
            action.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: action.isAdd
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      action.isAdd
                          ? l.add.toUpperCase()
                          : l.update.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: action.isAdd
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  ServiceBadge(
                    service: action.targetService,
                    size: 16,
                    compact: false,
                    showLabelWithIcon: false,
                    textStyle: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (action.isAdd)
                Text(
                  '${l.status}: ${_localizedSyncStatus(action.newStatus, l)} • ${l.score}: ${action.newScore} • ${l.episodesShort}: ${action.newProgress}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Text(
                  '${l.differenceShort}: ${_localizedSyncStatus(action.oldStatus ?? '', l)} ➔ ${_localizedSyncStatus(action.newStatus, l)} | ${l.score}: ${action.oldScore} ➔ ${action.newScore} | ${l.episodesShort}: ${action.oldProgress} ➔ ${action.newProgress}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
