import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsDynamicSchemeVariantCard extends StatelessWidget {
  const SettingsDynamicSchemeVariantCard({
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
    final themeSettings = ref.watch(themeSettingsProvider);

    const variants = <DynamicSchemeVariant, String>{
      DynamicSchemeVariant.tonalSpot: 'Tonal Spot',
      DynamicSchemeVariant.fidelity: 'Fidelity',
      DynamicSchemeVariant.vibrant: 'Vibrant',
      DynamicSchemeVariant.expressive: 'Expressive',
      DynamicSchemeVariant.neutral: 'Neutral',
      DynamicSchemeVariant.monochrome: 'Monochrome',
      DynamicSchemeVariant.fruitSalad: 'Fruit Salad',
      DynamicSchemeVariant.rainbow: 'Rainbow',
      DynamicSchemeVariant.content: 'Content',
    };

    return SettingsCard(
      icon: Icons.tune_rounded,
      title: "Variant Material 3",
      subtitle: "Controls tone and contrast generation algorithm",
      content: DropdownButtonFormField<DynamicSchemeVariant>(
        key: ValueKey('scheme_variant_${themeSettings.schemeVariant.name}'),
        initialValue: variants.containsKey(themeSettings.schemeVariant)
            ? themeSettings.schemeVariant
            : DynamicSchemeVariant.tonalSpot,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
        ),
        isExpanded: true,
        items: variants.entries.map((e) {
          return DropdownMenuItem<DynamicSchemeVariant>(
            value: e.key,
            child: Text(e.value, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            ref.read(themeSettingsProvider.notifier).setSchemeVariant(val);
          }
        },
      ),
    );
  }
}
