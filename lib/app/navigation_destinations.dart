import 'package:flutter/material.dart';

class AppDestination {
  const AppDestination({
    required this.path,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.selectedIcon,
    this.showInBottomNav = false,
  });

  final String path;
  final String label;

  /// Trimmed label that fits a phone bottom navigation bar.
  final String shortLabel;
  final IconData icon;
  final IconData selectedIcon;
  final bool showInBottomNav;
}

abstract final class AppDestinations {
  static const dashboard = AppDestination(
    path: '/',
    label: 'Dashboard',
    shortLabel: 'Home',
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
    showInBottomNav: true,
  );

  static const checkIn = AppDestination(
    path: '/check-in',
    label: 'Guest Check-in',
    shortLabel: 'Check-in',
    icon: Icons.login_rounded,
    selectedIcon: Icons.login_rounded,
    showInBottomNav: true,
  );

  static const booking = AppDestination(
    path: '/booking',
    label: 'Room Booking',
    shortLabel: 'Booking',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    showInBottomNav: true,
  );

  static const checkOut = AppDestination(
    path: '/check-out',
    label: 'Guest Check-out',
    shortLabel: 'Check-out',
    icon: Icons.logout_rounded,
    selectedIcon: Icons.logout_rounded,
    showInBottomNav: true,
  );

  static const rooms = AppDestination(
    path: '/rooms',
    label: 'Rooms',
    shortLabel: 'Rooms',
    icon: Icons.meeting_room_outlined,
    selectedIcon: Icons.meeting_room_rounded,
  );

  static const reports = AppDestination(
    path: '/reports',
    label: 'Reports',
    shortLabel: 'Reports',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
  );

  static const profile = AppDestination(
    path: '/profile',
    label: 'Profile',
    shortLabel: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  );

  static const all = [
    dashboard,
    checkIn,
    booking,
    checkOut,
    rooms,
    reports,
    profile,
  ];

  /// Primary phone tabs. Rooms and Reports live under the More sheet.
  static List<AppDestination> get bottomNav =>
      all.where((d) => d.showInBottomNav).toList();

  /// Extra destinations surfaced from the More tab.
  static const more = [rooms, reports];

  /// Index of the More tab in the 5-item phone navigation bar.
  static int get moreTabIndex => bottomNav.length;

  static String labelForPath(String path) {
    for (final destination in all) {
      if (destination.path == path) return destination.label;
    }
    return 'Raintech Hotel';
  }
}
