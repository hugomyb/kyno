import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/workout_ui_state.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/exercises_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/program_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/session_editor_screen.dart';
import '../ui/screens/sessions_screen.dart';
import '../ui/screens/workout_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/sessions',
        builder: (context, state) => const SessionsScreen(),
      ),
      GoRoute(
        path: '/exercises',
        builder: (context, state) => const ExercisesScreen(),
      ),
      GoRoute(
        path: '/sessions/new',
        builder: (context, state) => const SessionEditorScreen(),
      ),
      GoRoute(
        path: '/sessions/:id',
        builder: (context, state) => SessionEditorScreen(
          sessionId: state.pathParameters['id'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => NavScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/program',
            builder: (context, state) => const ProgramScreen(),
          ),
          GoRoute(
            path: '/workout',
            builder: (context, state) => WorkoutScreen(
              sessionId: state.uri.queryParameters['sessionId'],
              restart: state.uri.queryParameters['restart'] == '1',
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }
      if (authState.isAuthenticated && isLoggingIn) {
        return '/';
      }
      return null;
    },
  );
});

class NavScaffold extends StatelessWidget {
  const NavScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return ValueListenableBuilder<bool>(
      valueListenable: workoutActive,
      builder: (context, isActive, _) {
        return Scaffold(
          body: SafeArea(child: child),
          bottomNavigationBar: isActive
              ? null
              : SafeArea(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17203A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF17203A).withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NavPill(
                          icon: Icons.home,
                          label: 'Accueil',
                          selected: _indexForLocation(location) == 0,
                          onTap: () => context.go('/'),
                        ),
                        _NavPill(
                          icon: Icons.fitness_center,
                          label: 'Programme',
                          selected: _indexForLocation(location) == 1,
                          onTap: () => context.go('/program'),
                        ),
                        _NavPill(
                          icon: Icons.person,
                          label: 'Profil',
                          selected: _indexForLocation(location) == 2,
                          onTap: () => context.go('/profile'),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/program')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2C3550) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: selected ? 1 : 0.7),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: selected ? 1 : 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
