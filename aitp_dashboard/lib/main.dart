import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/auth_session.dart';
import 'core/theme.dart';
import 'core/dashboard_provider.dart';
import 'widgets/dashboard_layout.dart';
import 'features/dashboard/overview_view.dart';
import 'features/dashboard/trips_view.dart';
import 'features/dashboard/users_view.dart';
import 'features/catalog/catalog_view.dart';
import 'features/analytics/analytics_view.dart';
import 'features/settings/settings_view.dart';
import 'features/auth/login_view.dart';

void main() {
  runApp(const ProviderScope(child: AitpDashboardApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AitpDashboardApp extends ConsumerStatefulWidget {
  const AitpDashboardApp({super.key});

  @override
  ConsumerState<AitpDashboardApp> createState() => _AitpDashboardAppState();
}

class _AitpDashboardAppState extends ConsumerState<AitpDashboardApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/overview',
      navigatorKey: _rootNavigatorKey,
      refreshListenable: authSession,
      redirect: (context, state) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        final isLoggingIn = state.matchedLocation == '/login';

        if (token == null && !isLoggingIn) {
          return '/login';
        }
        if (token != null && isLoggingIn) {
          return '/overview';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginView()),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            final String location = state.matchedLocation;
            int selectedIndex = 0;
            String pageTitle = 'Dashboard Overview';

            if (location == '/overview') {
              selectedIndex = 0;
              pageTitle = 'Dashboard Overview';
            } else if (location == '/trips') {
              selectedIndex = 1;
              pageTitle = 'Trip Management';
            } else if (location == '/users') {
              selectedIndex = 2;
              pageTitle = 'User Management';
            } else if (location == '/catalog') {
              selectedIndex = 3;
              pageTitle = 'Package Catalog';
            } else if (location == '/analytics') {
              selectedIndex = 4;
              pageTitle = 'Advanced Analytics';
            } else if (location == '/settings') {
              selectedIndex = 5;
              pageTitle = 'System Settings';
            }

            final provider = ref.watch(dashboardProvider);
            final adminName =
                provider.adminProfile['name']?.toString() ?? 'Admin User';
            final adminRole =
                (provider.adminProfile['role']?.toString() ?? 'admin')
                    .toUpperCase();

            return DashboardLayout(
              adminName: adminName,
              adminRole: adminRole,
              selectedIndex: selectedIndex,
              pageTitle: pageTitle,
              onIndexChanged: (index) {
                switch (index) {
                  case 0:
                    context.go('/overview');
                    break;
                  case 1:
                    context.go('/trips');
                    break;
                  case 2:
                    context.go('/users');
                    break;
                  case 3:
                    context.go('/catalog');
                    break;
                  case 4:
                    context.go('/analytics');
                    break;
                  case 5:
                    context.go('/settings');
                    break;
                }
              },
              content: child,
            );
          },
          routes: [
            GoRoute(
              path: '/overview',
              builder: (context, state) => const OverviewView(),
            ),
            GoRoute(
              path: '/trips',
              builder: (context, state) => const TripsView(),
            ),
            GoRoute(
              path: '/users',
              builder: (context, state) => const UsersView(),
            ),
            GoRoute(
              path: '/catalog',
              builder: (context, state) => const CatalogView(),
            ),
            GoRoute(
              path: '/pricing',
              redirect: (context, state) => '/overview',
            ),
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsView(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsView(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AITP Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dashTheme,
      routerConfig: _router,
    );
  }
}
