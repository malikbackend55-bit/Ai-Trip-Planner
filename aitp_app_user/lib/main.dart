import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth_provider.dart';
import 'core/trip_provider.dart';
import 'core/theme.dart';
import 'features/auth/splash_view.dart';
import 'features/main_navigation.dart';
import 'features/auth/login_view.dart';
import 'features/auth/register_view.dart';
import 'features/auth/forgot_password_view.dart';
import 'features/trips/create_trip_form.dart';
import 'features/itinerary/itinerary_view.dart';
import 'features/chat/chat_view.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterView(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) {
            final extra = state.extra;
            final initialEmail = extra is String ? extra : null;
            return ForgotPasswordView(initialEmail: initialEmail);
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            final tabIndex = state.extra as int? ?? 0;
            return MainNavigation(initialIndex: tabIndex);
          },
        ),
        GoRoute(
          path: '/create-trip',
          builder: (context, state) {
            final extra = state.extra;
            final trip = extra is Map ? Map<String, dynamic>.from(extra) : null;
            return CreateTripForm(trip: trip);
          },
        ),
        GoRoute(
          path: '/itinerary',
          builder: (context, state) {
            final trip = state.extra as Map<String, dynamic>;
            return ItineraryView(trip: trip);
          },
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) {
            final trip = state.extra as Map<String, dynamic>?;
            return ChatView(trip: trip);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Trip Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      await ref.read(tripProvider).fetchTrips();
      if (!mounted) return;
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashView();
  }
}
