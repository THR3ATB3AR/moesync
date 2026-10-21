import 'dart:async';

import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'providers/providers.dart';
import 'router.dart';
import 'services/env.dart';
import 'services/release_service.dart';
import 'services/storage_service.dart';
import 'widgets/update_available_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.init();
  final storage = await StorageService.create();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> with WidgetsBindingObserver {
  bool _isCheckingReleases = false;
  String? _lastPromptedReleaseTag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkReleasesAutomatically();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkReleasesAutomatically();
    }
  }

  Future<void> _checkReleasesAutomatically() async {
    if (_isCheckingReleases) return;
    _isCheckingReleases = true;
    try {
      final release = await ref
          .read(releaseServiceProvider)
          .checkAutomatically();
      if (release == null || release.tagName == _lastPromptedReleaseTag) return;

      final packageInfo = await PackageInfo.fromPlatform();
      if (!ReleaseService.isUpdateAvailable(packageInfo.version, release)) {
        return;
      }

      final dialogContext = rootNavigatorKey.currentContext;
      if (!mounted || dialogContext == null || !dialogContext.mounted) return;
      _lastPromptedReleaseTag = release.tagName;
      unawaited(
        showDialog<void>(
          context: dialogContext,
          builder: (context) => UpdateAvailableDialog(
            release: release,
            currentVersion: packageInfo.version,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Automatic release check failed: $error');
    } finally {
      _isCheckingReleases = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(routerProvider);
    final themeSettings = ref.watch(themeSettingsProvider);
    final appLocale = ref.watch(languageSettingsProvider).locale;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightTheme = themeSettings.buildLightTheme(
          dynamicSeedColor: lightDynamic?.primary,
        );
        final darkTheme = themeSettings.buildDarkTheme(
          dynamicSeedColor: darkDynamic?.primary,
        );

        return MaterialApp.router(
          title: 'MoeSync',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeSettings.themeMode,
          routerConfig: goRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en'), Locale('pl'), Locale('es')],
          locale: appLocale,
        );
      },
    );
  }
}
