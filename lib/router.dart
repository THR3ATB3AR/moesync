import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/screens/media_detail_screen.dart';
import 'package:moesync/screens/settings/settings_about_page.dart';
import 'package:moesync/screens/settings/settings_appearance_page.dart';
import 'package:moesync/screens/settings/settings_language_page.dart';
import 'package:moesync/screens/settings/settings_sources_database_page.dart';
import 'package:moesync/screens/staff_cast_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/anime_screen.dart';
import 'screens/home_screen.dart';
import 'screens/manga_screen.dart';
import 'screens/more_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sync_screen.dart';
import 'screens/settings/settings_accounts_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: <GoRoute>[
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/anime',
            builder: (context, state) => const AnimeScreen(),
          ),
          GoRoute(
            path: '/manga',
            builder: (context, state) => const MangaScreen(),
          ),
          GoRoute(
            path: '/mediaDetails',
            pageBuilder: (context, state) {
              final item = state.extra as UnifiedMediaItem?;
              return CustomTransitionPage(
                key: state.pageKey,
                child: MediaDetailScreen(item: item!),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: '/staffCastDetail',
            pageBuilder: (context, state) {
              final args = state.extra as Map<String, dynamic>?;
              final staffCastId = args?['staffCastId'];
              final malId = args?['malId'];
              final staffCastName = args?['staffCastName'];
              final imageUrl = args?['imageUrl'];
              final staffCastType = args?['staffCastType'];
              final role = args?['role'];
              return CustomTransitionPage(
                key: state.pageKey,
                child: StaffCastDetailScreen(
                  staffCastId: staffCastId!,
                  malId: malId,
                  staffCastName: staffCastName!,
                  imageUrl: imageUrl,
                  staffCastType: staffCastType!,
                  role: role,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: '/sync',
            builder: (context, state) => const SyncScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
          ),
          GoRoute(
            path: '/more/settings',
            pageBuilder: (context, state) {
              final category = state.uri.queryParameters['category'];
              return CustomTransitionPage(
                key: state.pageKey,
                child: SettingsScreen(initialCategory: category),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: '/more/settings/accounts',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsAccountsPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: '/more/settings/tracking',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsAccountsPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: '/more/settings/appearance',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsAppearancePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: '/more/settings/language',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsLanguagePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: '/more/settings/sources',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsSourcesDatabasePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: '/more/settings/database',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsSourcesDatabasePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: '/more/settings/about',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsAboutPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (int idx) => _onItemTapped(idx, context),
        destinations: [
          NavigationDestination(
            key: Key('home'),
            icon: Icon(Icons.dashboard_outlined),
            label: AppLocalizations.of(context).home,
            selectedIcon: Icon(Icons.dashboard_rounded),
          ),
          NavigationDestination(
            key: Key('anime'),
            icon: Icon(Icons.movie_filter_outlined),
            label: AppLocalizations.of(context).anime,
            selectedIcon: Icon(Icons.movie_filter_rounded),
          ),
          NavigationDestination(
            key: Key('manga'),
            icon: Icon(Icons.menu_book_outlined),
            label: AppLocalizations.of(context).manga,
            selectedIcon: Icon(Icons.menu_book_rounded),
          ),
          NavigationDestination(
            key: Key('sync'),
            icon: Icon(Icons.sync_outlined),
            label: AppLocalizations.of(context).sync,
            selectedIcon: Icon(Icons.sync_rounded),
          ),
          NavigationDestination(
            key: Key('more'),
            icon: Icon(Icons.more_horiz_outlined),
            label: AppLocalizations.of(context).more,
            selectedIcon: Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    try {
      final String location = GoRouterState.of(context).uri.toString();
      if (location.startsWith('/anime')) {
        return 1;
      }
      if (location.startsWith('/manga')) {
        return 2;
      }
      if (location.startsWith('/sync') || location.startsWith('/updates')) {
        return 3;
      }
      if (location.startsWith('/more')) {
        return 4;
      }
    } catch (_) {}
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/anime');
        break;
      case 2:
        context.go('/manga');
        break;
      case 3:
        context.go('/sync');
        break;
      case 4:
        context.go('/more');
        break;
    }
  }
}
