import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/booking/event_ticket_selection_screen.dart';
import '../features/booking/seat_selection_screen.dart';
import '../features/booking/showtimes_screen.dart';
import '../features/browse/browse_screen.dart';
import '../features/events/event_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/live_events/live_events_screen.dart';
import '../features/movies/movie_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/search/search_screen.dart';
import '../features/tickets/tickets_screen.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

/// go_router's default [StatefulShellRoute.indexedStack] wraps inactive branches in
/// [Offstage], which reports **zero** size. The stack can then size to 0×0, so the
/// active tab's [Navigator] gets no height (blank body with a visible bottom bar).
/// Filling the stack avoids that while keeping state for all branches.
Widget _shellBranchStack(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) {
  final i = navigationShell.currentIndex;
  return Stack(
    fit: StackFit.expand,
    children: [
      for (var j = 0; j < children.length; j++)
        Positioned.fill(
          child: IgnorePointer(
            ignoring: j != i,
            child: TickerMode(
              enabled: j == i,
              child: children[j],
            ),
          ),
        ),
    ],
  );
}

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: _shellBranchStack,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  key: ValueKey('home'),
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                name: 'movies',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  key: ValueKey('movies'),
                  child: BrowseScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/live-events',
                name: 'liveEvents',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  key: ValueKey('liveEvents'),
                  child: LiveEventsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  key: ValueKey('profile'),
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/my-tickets',
        name: 'myTickets',
        builder: (context, state) => const TicketsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final q = state.uri.queryParameters['q'];
          final scope = state.uri.queryParameters['scope'];
          final pill = int.tryParse(state.uri.queryParameters['pill'] ?? '');
          return SearchScreen(initialQuery: q, scope: scope, initialPill: pill);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/movie/:movieId',
        name: 'movie',
        builder: (context, state) {
          final id = state.pathParameters['movieId']!;
          return MovieDetailScreen(movieId: id);
        },
        routes: [
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: 'showtimes',
            name: 'showtimes',
            builder: (context, state) {
              final id = state.pathParameters['movieId']!;
              return ShowtimesScreen(movieId: id);
            },
            routes: [
              GoRoute(
                parentNavigatorKey: _rootKey,
                path: ':showtimeId/seats',
                name: 'seats',
                builder: (context, state) {
                  final movieId = state.pathParameters['movieId']!;
                  final showtimeId = state.pathParameters['showtimeId']!;
                  final n = int.tryParse(state.uri.queryParameters['n'] ?? '') ?? 2;
                  return SeatSelectionScreen(movieId: movieId, showtimeId: showtimeId, seatCount: n);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/event/:eventId',
        name: 'event',
        builder: (context, state) {
          final id = state.pathParameters['eventId']!;
          return EventDetailScreen(eventId: id);
        },
        routes: [
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: 'tickets',
            name: 'eventTickets',
            builder: (context, state) {
              final id = state.pathParameters['eventId']!;
              return EventTicketSelectionScreen(eventId: id);
            },
          ),
        ],
      ),
    ],
  );
}
