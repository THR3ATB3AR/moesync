import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/media_item.dart';
import '../providers/providers.dart';

class SearchMediaDialog extends ConsumerStatefulWidget {
  final MediaType mediaType;

  const SearchMediaDialog({super.key, required this.mediaType});

  @override
  ConsumerState<SearchMediaDialog> createState() => _SearchMediaDialogState();
}

class _SearchMediaDialogState extends ConsumerState<SearchMediaDialog> {
  final _controller = TextEditingController();
  bool _isSearching = false;
  List<MediaItem> _results = [];
  String? _error;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final anilist = ref.read(anilistServiceProvider);
      final mal = ref.read(malServiceProvider);

      List<MediaItem> items = [];
      items = await anilist.search(query, widget.mediaType);
      if (items.isEmpty) {
        items = await mal.search(query, widget.mediaType);
      }

      setState(() {
        _results = items;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search: $e';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnime = widget.mediaType == MediaType.anime;
    final titleLanguage = ref.watch(languageSettingsProvider).titleLanguage;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isAnime ? Icons.movie_filter_rounded : Icons.menu_book,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Search & Add ${isAnime ? 'Anime' : 'Manga'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter title (e.g. Frieren, Berserk)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _performSearch(_controller.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onSubmitted: _performSearch,
              ),
              const SizedBox(height: 16),
              if (_isSearching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                )
              else if (_results.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Type a name and press search',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        onTap: () {
                          final unified = UnifiedMediaItem(
                            malId: item.malId ?? 0,
                            title: item.title,
                            posterImage: item.posterImage,
                            mediaType: widget.mediaType,
                            services: {item.service: item},
                          );
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push('/mediaDetails', extra: unified);
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.posterImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: item.posterImage,
                                  width: 44,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                )
                              : Container(
                                  width: 44,
                                  height: 60,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.movie),
                                ),
                        ),
                        title: Text(
                          item.titleFor(titleLanguage),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item.totalProgress != null
                              ? '${item.totalProgress} ${isAnime ? 'episodes' : 'chapters'}'
                              : 'Ongoing',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            final unified = UnifiedMediaItem(
                              malId: item.malId ?? 0,
                              title: item.title,
                              posterImage: item.posterImage,
                              mediaType: widget.mediaType,
                              services: {item.service: item},
                            );
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await ref
                                  .read(mediaLibraryProvider.notifier)
                                  .addItemToAllServices(
                                  item: unified,
                                  status: isAnime ? 'watching' : 'reading',
                                  score: 8,
                                  progress: 1,
                                );
                              if (!mounted) return;
                              Navigator.pop(context);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added "${item.title}" to connected services!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not add to connected services: $error',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Add'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
