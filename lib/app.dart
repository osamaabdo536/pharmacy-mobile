import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/storage/local_storage.dart';
import 'features/onboarding/ui/splash_screen.dart';

import 'features/home/ui/home_screen.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/register_screen.dart';
import 'features/search/ui/search_screen.dart';
import 'features/chat/ui/chat_screen.dart';
import 'features/reservation/ui/reservation_screen.dart';
import 'features/notifications/ui/notifications_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MedConnect',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    GoRoute(
      path: '/reservation/:id',
      builder: (context, state) =>
          ReservationScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),
  ],
  redirect: (context, state) {
    final isLoggedIn = TokenStorage.hasToken();
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/home';
    return null;
  },
);