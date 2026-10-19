import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsMediaViewModeCard extends StatelessWidget {
  const SettingsMediaViewModeCard({
    super.key,
    required this.context,
    required this.ref,
    required this.theme,
  });

  final BuildContext context;
  final WidgetRef ref;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(mediaViewModeProvider);

    return SettingsCard(
      icon: Icons.dashboard_customize_rounded,
      title: "Layout style",
      subtitle: 'Set layout style for anime and manga collections',
      content: SegmentedButton<MediaViewMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: MediaViewMode.grid,
            icon: Icon(Icons.grid_view_rounded, size: 16),
            label: Text('Siatka (Grid)'),
          ),
          ButtonSegment(
            value: MediaViewMode.list,
            icon: Icon(Icons.view_agenda_rounded, size: 16),
            label: Text('Lista (List)'),
          ),
        ],
        selected: {currentMode},
        onSelectionChanged: (set) {
          if (set.isNotEmpty) {
            ref.read(mediaViewModeProvider.notifier).setMode(set.first);
          }
        },
      ),
    );
  }
}
