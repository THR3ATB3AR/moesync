import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/screens/settings/settings_home_screen_page.dart';
import 'package:moesync/services/storage_service.dart';
import 'package:moesync/widgets/home/home_widget_ids.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('home widget order and visibility persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final container = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(homeScreenWidgetSettingsProvider.notifier);
    await notifier.setEnabled(homeWidgetStatsId, false);
    await notifier.reorder(0, 2);

    expect(
      container.read(homeScreenWidgetSettingsProvider).order[2],
      homeWidgetSyncStatusId,
    );
    expect(
      container
          .read(homeScreenWidgetSettingsProvider)
          .isEnabled(homeWidgetStatsId),
      isFalse,
    );

    final reloaded = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(reloaded.dispose);
    expect(
      reloaded.read(homeScreenWidgetSettingsProvider).order[2],
      homeWidgetSyncStatusId,
    );
    expect(
      reloaded
          .read(homeScreenWidgetSettingsProvider)
          .isEnabled(homeWidgetStatsId),
      isFalse,
    );
  });

  testWidgets('home widget settings list fits narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsHomeScreenPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue Watching'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
