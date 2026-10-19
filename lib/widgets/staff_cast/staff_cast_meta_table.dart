import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/screens/staff_cast_details_screen.dart';
import 'package:flutter/material.dart';

class StaffCastMetaTable extends StatelessWidget {
  const StaffCastMetaTable({
    super.key,
    required this.staffData,
    required this.context,
    required this.widget,
    required this.characterData,
    required this.theme,
  });

  final StaffDetailData? staffData;
  final BuildContext context;
  final StaffCastDetailScreen widget;
  final CharacterDetailData? characterData;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final occupations = staffData?.occupations ?? [];
    final occString = occupations.isNotEmpty
        ? occupations.join(', ')
        : AppLocalizations.of(context).voiceActor;

    final rows = widget.staffCastType == StaffCastType.staff
        ? [
            MapEntry(
              AppLocalizations.of(context).birthday,
              staffData?.birthday ?? AppLocalizations.of(context).unknown,
            ),
            if (staffData!.deathday != null)
              MapEntry(
                AppLocalizations.of(context).deathday,
                staffData?.deathday ?? AppLocalizations.of(context).unknown,
              ),
            MapEntry(
              AppLocalizations.of(context).age,
              staffData?.age != null
                  ? '${staffData!.age}'
                  : AppLocalizations.of(context).unknown,
            ),
            MapEntry(
              AppLocalizations.of(context).gender,
              staffData?.gender ?? AppLocalizations.of(context).unknown,
            ),
            MapEntry(
              AppLocalizations.of(context).bloodType,
              staffData?.bloodType ?? AppLocalizations.of(context).unknown,
            ),
            MapEntry(
              AppLocalizations.of(context).yearsActive,
              staffData?.yearsActive ?? AppLocalizations.of(context).unknown,
            ),
            MapEntry(
              AppLocalizations.of(context).hometown,
              staffData?.homeTown ?? AppLocalizations.of(context).unknown,
            ),
            MapEntry(AppLocalizations.of(context).occupations, occString),
          ]
        : [
            MapEntry(
              AppLocalizations.of(context).birthday,
              characterData?.dateOfBirth ??
                  AppLocalizations.of(context).unknown,
            ),
            MapEntry(
              AppLocalizations.of(context).age,
              characterData?.age != null
                  ? '${characterData!.age}'
                  : AppLocalizations.of(context).unknown,
            ),
            MapEntry(
              AppLocalizations.of(context).gender,
              characterData?.gender ?? AppLocalizations.of(context).unknown,
            ),
            MapEntry(
              AppLocalizations.of(context).bloodType,
              characterData?.bloodType ?? AppLocalizations.of(context).unknown,
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: rows.map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 125,
                  child: Text(
                    r.key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
