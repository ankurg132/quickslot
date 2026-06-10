import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_notifier.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/venues/presentation/venue_list_screen.dart';
import '../features/venues/presentation/venue_detail_screen.dart';
import '../features/bookings/presentation/my_bookings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }
      if (isLoggedIn && isGoingToLogin) {
        return '/venues';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/venues',
        builder: (context, state) => const VenueListScreen(),
      ),
      GoRoute(
        path: '/venues/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return VenueDetailScreen(venueId: id);
        },
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
    ],
  );
});
