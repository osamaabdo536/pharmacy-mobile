import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/storage/local_storage.dart';
import 'core/utils/location_service.dart';
import 'features/auth/data/models/auth_repository.dart';
import 'features/chat/cubit/chat_cubit.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/reservation/ui/reservations_list_screen.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/main_shell.dart';

import 'features/onboarding/ui/splash_screen.dart';
import 'features/onboarding/ui/onboarding_screen.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/register_screen.dart';
import 'features/auth/cubit/auth_cubit.dart';

import 'features/search/ui/search_screen.dart';
import 'features/reservation/ui/reservation_screen.dart';
import 'features/chat/ui/chat_screen.dart';
import 'features/profile/ui/profile_screen.dart';
import 'features/notifications/ui/notifications_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => AuthRepository()),
        RepositoryProvider<ChatRepository>(create: (_) => ChatRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(context.read<AuthRepository>()),
          ),
          BlocProvider<ChatCubit>(
            create: (context) => ChatCubit(
              repository: context.read<ChatRepository>(),
              locationService: LocationService(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Dawak',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    // ─── Full-screen routes (pushed on top, no bottom nav) ───
    GoRoute(
      path: '/reservation/:id',
      builder: (context, state) =>
          ReservationScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),
    GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),

    // ─── Bottom navigation shell (3 tabs: Search, Reservations, Profile) ─
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reservations',
              builder: (_, __) => const ReservationsListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final isLoggedIn = TokenStorage.hasToken();
    final location = state.matchedLocation;
    final isPublicRoute = location == '/' ||
        location == '/onboarding' ||
        location == '/login' ||
        location == '/register';

    if (!isLoggedIn && !isPublicRoute) return '/login';
    if (isLoggedIn && (location == '/login' || location == '/register')) {
      return '/search';
    }
    return null;
  },
);
