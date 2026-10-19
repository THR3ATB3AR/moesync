import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/staff_cast/staff_cast_characters_tab.dart';
import 'package:moesync/widgets/staff_cast/staff_cast_info_tab.dart';
import 'package:moesync/widgets/staff_cast/staff_cast_media_character_appearances_tab.dart';
import 'package:moesync/widgets/staff_cast/staff_cast_media_tab.dart';
import 'package:moesync/widgets/tab_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/media_detail_data.dart';
import '../providers/providers.dart';
import '../widgets/skeleton_loader.dart';

class StaffCastDetailScreen extends ConsumerStatefulWidget {
  final int staffCastId;
  final int? malId;
  final String staffCastName;
  final String? imageUrl;
  final StaffCastType staffCastType;
  final String? language;
  final String? role;

  const StaffCastDetailScreen({
    super.key,
    required this.staffCastId,
    this.malId,
    required this.staffCastName,
    this.imageUrl,
    this.language,
    required this.staffCastType,
    this.role,
  });

  @override
  ConsumerState<StaffCastDetailScreen> createState() =>
      _StaffCastDetailScreenState();
}

class _StaffCastDetailScreenState extends ConsumerState<StaffCastDetailScreen> {
  int _activeTab = 0;
  String _mediaFilter = 'all';
  String _characterFilter = 'all';
  bool _isLoading = true;
  bool _isFavorite = false;
  StaffDetailData? _staffData;
  CharacterDetailData? _characterData;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final service = ref.read(mediaDetailServiceProvider);
    if (widget.staffCastType == StaffCastType.staff) {
      try {
        final data = await service.fetchStaffDetails(
          id: widget.staffCastId,
          malId: widget.malId,
          name: widget.staffCastName,
          forceRefresh: forceRefresh,
        );
        if (mounted) {
          setState(() {
            _staffData = data;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      try {
        final data = await service.fetchCharacterDetails(
          id: widget.staffCastId,
          malId: widget.malId,
          name: widget.staffCastName,
          forceRefresh: forceRefresh,
        );
        if (mounted) {
          setState(() {
            _characterData = data;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text: widget.staffCastType == StaffCastType.staff
            ? 'https://anilist.co/staff/${widget.staffCastId}'
            : 'https://anilist.co/character/${widget.staffCastId}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.staffCastType == StaffCastType.staff
              ? AppLocalizations.of(context).personShared(widget.staffCastName)
              : AppLocalizations.of(
                  context,
                ).characterShared(widget.staffCastName),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openInBrowser() async {
    launchUrl(
      Uri.parse(
        widget.staffCastType == StaffCastType.staff
            ? 'https://anilist.co/staff/${widget.staffCastId}'
            : 'https://anilist.co/character/${widget.staffCastId}',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = widget.staffCastType == StaffCastType.staff
        ? (_staffData?.name ?? widget.staffCastName)
        : (_characterData?.name ?? widget.staffCastName);
    final displayImage = widget.staffCastType == StaffCastType.staff
        ? (_staffData?.imageUrl ?? widget.imageUrl)
        : (_characterData?.imageUrl ?? widget.imageUrl);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: AppLocalizations.of(context).back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.redAccent : null,
            ),
            tooltip: AppLocalizations.of(context).favorites,
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: AppLocalizations.of(context).openInBrowser,
            onPressed: _openInBrowser,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: AppLocalizations.of(context).share,
            onPressed: _share,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TabPill(
                    icon: Icons.info_outline_rounded,
                    index: 0,
                    tooltip: AppLocalizations.of(context).information,
                    theme: theme,
                    activeTab: _activeTab,
                    onTap: (index) => setState(() => _activeTab = index),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TabPill(
                    icon: Icons.theaters_outlined,
                    index: 1,
                    tooltip: widget.staffCastType == StaffCastType.staff
                        ? AppLocalizations.of(
                            context,
                          ).performancesAndProductions
                        : AppLocalizations.of(context).appearances,
                    theme: theme,
                    activeTab: _activeTab,
                    onTap: (index) => setState(() => _activeTab = index),
                  ),
                ),
                const SizedBox(width: 10),
                (_staffData?.characterRoles.isEmpty ?? true)
                    ? SizedBox.shrink()
                    : Expanded(
                        child: TabPill(
                          icon: Icons.record_voice_over_outlined,
                          index: 2,
                          tooltip: AppLocalizations.of(context).characters,
                          theme: theme,
                          activeTab: _activeTab,
                          onTap: (index) => setState(() => _activeTab = index),
                        ),
                      ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadDetails(forceRefresh: true),
              child:
                  widget.staffCastType == StaffCastType.staff &&
                      _isLoading &&
                      _staffData == null
                  ? StaffCastDetailSkeleton(
                      staffCastName: displayName,
                      imageUrl: displayImage,
                      staffCastType: widget.staffCastType,
                    )
                  : widget.staffCastType == StaffCastType.character &&
                        _isLoading &&
                        _characterData == null
                  ? StaffCastDetailSkeleton(
                      staffCastName: displayName,
                      imageUrl: displayImage,
                      staffCastType: widget.staffCastType,
                    )
                  : _buildTabContent(theme, displayName, displayImage),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    ThemeData theme,
    String displayName,
    String? displayImage,
  ) {
    switch (_activeTab) {
      case 0:
        return StaffCastInfoTab(
          widget: widget,
          staffData: _staffData,
          characterData: _characterData,
          context: context,
          theme: theme,
          displayName: displayName,
          displayImage: displayImage,
        );
      case 1:
        return widget.staffCastType == StaffCastType.staff
            ? StaffCastMediaTab(
                ref: ref,
                staffData: _staffData!,
                theme: theme,
                mediaFilter: _mediaFilter,
                setFilter: setMediaFilter,
              )
            : StaffCastMediaCharacterAppearancesTab(
                characterData: _characterData!,
                ref: ref,
                theme: theme,
              );
      case 2:
        return widget.staffCastType == StaffCastType.staff
            ? StaffCastCharactersTab(
                staffData: _staffData!,
                ref: ref,
                theme: theme,
                characterFilter: _characterFilter,
                setCharacterFilter: setCharacterFilter,
              )
            : const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  void setMediaFilter(String filter) {
    setState(() {
      _mediaFilter = filter;
    });
  }

  void setCharacterFilter(String filter) {
    setState(() {
      _characterFilter = filter;
    });
  }
}
