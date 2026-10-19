import 'dart:math';

import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/widgets/media/details/media_section_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/media_item.dart';

bool get isRunningInFlutterTest {
  final binding = WidgetsBinding.instance;
  return binding.runtimeType.toString().contains('Test');
}

class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final bool isCircle;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
    this.isCircle = false,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(
      begin: 0.45,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (!isRunningInFlutterTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: baseColor.withValues(
              alpha: isRunningInFlutterTest ? 0.6 : _animation.value,
            ),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class MediaDetailSkeleton extends StatelessWidget {
  final UnifiedMediaItem? liveItem;

  const MediaDetailSkeleton({super.key, this.liveItem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = liveItem?.posterImage;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 125,
                  height: 180,
                  child: posterUrl != null && posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const SkeletonBox(
                            width: 125,
                            height: 180,
                            borderRadius: 16,
                          ),
                          errorWidget: (_, _, _) => const SkeletonBox(
                            width: 125,
                            height: 180,
                            borderRadius: 16,
                          ),
                        )
                      : const SkeletonBox(
                          width: 125,
                          height: 180,
                          borderRadius: 16,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (liveItem?.title != null &&
                        liveItem!.title.isNotEmpty) ...[
                      Text(
                        liveItem!.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      const SkeletonBox(
                        height: 20,
                        width: double.infinity,
                        borderRadius: 8,
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SkeletonBox(height: 16, width: 130, borderRadius: 8),
                    const SizedBox(height: 10),
                    const SkeletonBox(height: 16, width: 155, borderRadius: 8),
                    const SizedBox(height: 10),
                    const SkeletonBox(height: 16, width: 115, borderRadius: 8),
                    const SizedBox(height: 10),
                    const SkeletonBox(height: 16, width: 85, borderRadius: 8),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              MediaSectionHeader(
                theme: theme,
                title: AppLocalizations.of(context).serviceScores,
                icon: Icons.insights_rounded,
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context).dataScoresServiceWithData(1, 5),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 56,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    SkeletonBox(
                      width: (Random().nextDouble() * 32 + 100),
                      height: 56,
                      borderRadius: 10,
                    ),
                    SizedBox(width: 8),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 32,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    SkeletonBox(
                      width: (Random().nextDouble() * 38 + 82),
                      height: 32,
                      borderRadius: 10,
                    ),
                    SizedBox(width: 8),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              MediaSectionHeader(
                theme: theme,
                title: AppLocalizations.of(context).descriptionSummary,
                icon: Icons.description_rounded,
              ),
              const Spacer(),
              if (1 > 1)
                Text(
                  AppLocalizations.of(
                    context,
                  ).swipeHorizontallyDescriptionsCount(1, 5),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: const [
              SkeletonBox(width: 90, height: 32, borderRadius: 10),
              SizedBox(width: 8),
              SkeletonBox(width: 90, height: 32, borderRadius: 10),
              SizedBox(width: 8),
              SkeletonBox(width: 90, height: 32, borderRadius: 10),
            ],
          ),

          const SizedBox(height: 8),

          const SkeletonBox(
            width: double.infinity,
            height: 170,
            borderRadius: 16,
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).swipeLeftRightToCompareDescriptions,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context).expandDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          MediaSectionHeader(
            theme: theme,
            title: AppLocalizations.of(context).stats,
            icon: Icons.show_chart_rounded,
          ),
          const SizedBox(height: 10),
          const SkeletonBox(
            width: double.infinity,
            height: 110,
            borderRadius: 16,
          ),

          const SizedBox(height: 20),

          MediaSectionHeader(
            theme: theme,
            title: AppLocalizations.of(context).moreInformation,
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 12),

          Column(
            spacing: 8,
            children: List.generate(
              86,
              (index) => const SkeletonBox(
                width: double.infinity,
                height: 28,
                borderRadius: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StaffCastDetailSkeleton extends StatelessWidget {
  final String? staffCastName;
  final String? imageUrl;
  final StaffCastType staffCastType;

  const StaffCastDetailSkeleton({
    super.key,
    this.staffCastName,
    this.imageUrl,
    required this.staffCastType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 46,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: CachedNetworkImageProvider(imageUrl!),
                )
              else
                const SkeletonBox(width: 92, height: 92, isCircle: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (staffCastName != null && staffCastName!.isNotEmpty) ...[
                      Text(
                        staffCastName!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      const SkeletonBox(
                        height: 22,
                        width: 160,
                        borderRadius: 8,
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SkeletonBox(height: 14, width: 110, borderRadius: 6),
                    const SizedBox(height: 8),
                    const SkeletonBox(height: 14, width: 140, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          SkeletonBox(
            width: double.infinity,
            height: staffCastType == StaffCastType.staff ? 260 : 160,
            borderRadius: 16,
          ),

          const SizedBox(height: 24),
          if (staffCastType == StaffCastType.character) ...[
            MediaSectionHeader(
              theme: theme,
              title: AppLocalizations.of(context).voiceActors,
              icon: Icons.voice_chat,
            ),

            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: const SkeletonBox(
                      width: 120,
                      height: 50,
                      borderRadius: 16,
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const SkeletonBox(width: 100, height: 40, borderRadius: 16),
          ],
          const SizedBox(height: 24),
          MediaSectionHeader(
            theme: theme,
            title: AppLocalizations.of(context).biographyDescription,
            icon: Icons.person,
          ),
          const SizedBox(height: 10),
          const SkeletonBox(
            width: double.infinity,
            height: 180,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }
}

class HomeHorizontalMediaListSkeleton extends StatelessWidget {
  const HomeHorizontalMediaListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 245,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 130, height: 155, borderRadius: 16),
                const SizedBox(height: 8),
                const SkeletonBox(width: 130, height: 18, borderRadius: 6),
                const SizedBox(height: 8),
                Row(
                  spacing: 4,
                  children: [
                    const SkeletonBox(width: 18, height: 18, borderRadius: 6),
                    const SkeletonBox(width: 18, height: 18, borderRadius: 6),
                    const SkeletonBox(width: 18, height: 18, borderRadius: 6),
                    const SkeletonBox(width: 18, height: 18, borderRadius: 6),
                    const SkeletonBox(width: 18, height: 18, borderRadius: 6),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MediaScreenSkeleton extends StatelessWidget {
  const MediaScreenSkeleton({super.key, required this.viewType});
  final MediaViewMode viewType;

  @override
  Widget build(BuildContext context) {
    if (viewType == MediaViewMode.grid) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1 / 1.75,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
        ),
        itemCount: 6,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          return const SkeletonBox(width: 100, height: 185, borderRadius: 16);
        },
      );
    } else {
      return ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(4),
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(
                width: double.infinity,
                height: 145,
                borderRadius: 16,
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      );
    }
  }
}


class SyncScreenSkeleton extends StatelessWidget {
  const SyncScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SkeletonBox(width: 270, height: 60, borderRadius: 16),
              const SkeletonBox(width: 90, height: 40, borderRadius: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SkeletonBox(width: 110, height: 40, borderRadius: 8),
            const SkeletonBox(width: 110, height: 40, borderRadius: 8),
            const SkeletonBox(width: 110, height: 40, borderRadius: 8),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          spacing: 4,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SkeletonBox(width: 130, height: 20, borderRadius: 16),
            Row(
              spacing: 16,
              children: [
                const SkeletonBox(width: 80, height: 20, borderRadius: 16),
                const SkeletonBox(width: 60, height: 20, borderRadius: 16),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [SkeletonBox(width: 80, height: 20, borderRadius: 16)],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            padding: const EdgeInsets.all(4),
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(
                    width: double.infinity,
                    height: 110,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
