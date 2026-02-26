import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/app_lifecycle_provider.dart';
import '../providers/notifications_provider.dart';
import '../services/workout_ui_state.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/exercise_history_screen.dart';
import '../ui/screens/exercises_screen.dart';
import '../ui/screens/friends_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/notifications_screen.dart';
import '../ui/screens/program_screen.dart';
import '../ui/screens/program_sharing_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/session_editor_screen.dart';
import '../ui/screens/sessions_screen.dart';
import '../ui/screens/workout_screen.dart';

final routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (_, __) {
    notifier.value++;
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(appLifecycleProvider);
  final refreshListenable = ref.watch(routerRefreshProvider);
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/' : '/login',
    refreshListenable: refreshListenable,
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
        path: '/exercises/:id/history',
        builder: (context, state) => ExerciseHistoryScreen(
          exerciseId: state.pathParameters['id']!,
          exerciseName: state.uri.queryParameters['name'] ?? 'Exercice',
        ),
      ),
      GoRoute(
        path: '/program/sharing',
        builder: (context, state) => const ProgramSharingScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
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
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
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

class NavScaffold extends ConsumerWidget {
  const NavScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }
    final location = GoRouterState.of(context).uri.path;
    final unreadCount = ref.watch(notificationsProvider.select((s) => s.unreadCount));

    return ValueListenableBuilder<bool>(
      valueListenable: workoutActive,
      builder: (context, isActive, _) {
        return Scaffold(
          body: child,
          bottomNavigationBar: isActive
              ? null
              : SafeArea(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17203A).withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF17203A).withValues(alpha: 0.5),
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
                          badgeCount: unreadCount,
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
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.6)
                    : const Color(0xFF3B82F6).withValues(alpha: 0.15))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: selected
                        ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6))
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              badgeCount > 9 ? '9+' : badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6))
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
