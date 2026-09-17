import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_booking/app/main_shell.dart';
import 'package:hotel_booking/screens/dashboard_screen.dart';
import 'package:hotel_booking/screens/guest_checkin_screen.dart';
import 'package:hotel_booking/screens/guest_checkout_screen.dart';
import 'package:hotel_booking/screens/profile_screen.dart';
import 'package:hotel_booking/screens/reports_screen.dart';
import 'package:hotel_booking/screens/room_booking_screen.dart';
import 'package:hotel_booking/screens/rooms_screen.dart';
import 'package:hotel_booking/models/room.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/check-in',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GuestCheckinScreen()),
          ),
          GoRoute(
            path: '/check-out',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GuestCheckoutScreen()),
          ),
          GoRoute(
            path: '/booking',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RoomBookingScreen()),
          ),
          GoRoute(
            path: '/rooms',
            pageBuilder: (context, state) {
              final statusName = state.uri.queryParameters['status'];
              RoomStatus? filter;
              if (statusName != null) {
                for (final status in RoomStatus.values) {
                  if (status.name == statusName) {
                    filter = status;
                    break;
                  }
                }
              }

              return NoTransitionPage(
                key: ValueKey(state.uri.toString()),
                child: RoomsScreen(initialFilter: filter),
              );
            },
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
}
