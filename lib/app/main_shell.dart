import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_booking/app/navigation_destinations.dart';
import 'package:hotel_booking/data/staff_profile.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';

/// Mobile-first application shell: compact header, bottom navigation, and a
/// back button on every screen except Home.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Previous shell routes — powers header / system back for bottom-nav hops.
  final List<String> _backStack = [];

  String get _currentPath {
    final location = GoRouterState.of(context).uri.path;
    return location.isEmpty ? '/' : location;
  }

  bool get _canGoBack =>
      context.canPop() || _backStack.isNotEmpty;

  /// More-sheet screens opened via [context.go] still need a visible back affordance.
  bool _isSecondaryScreen(String path) =>
      AppDestinations.more.any((d) => d.path == path);

  bool get _showBackButton =>
      _canGoBack || _isSecondaryScreen(_currentPath);

  bool get _atNavigationRoot =>
      _currentPath == AppDestinations.dashboard.path &&
      _backStack.isEmpty &&
      !context.canPop();

  int _bottomNavIndex() {
    final index = AppDestinations.bottomNav.indexWhere(
      (d) => d.path == _currentPath,
    );
    if (index >= 0) return index;
    // Rooms, Reports, and any other secondary screen highlight More.
    return AppDestinations.moreTabIndex;
  }

  void _onBottomNavSelected(int index) {
    if (index == AppDestinations.moreTabIndex) {
      _openMoreSheet();
      return;
    }
    _navigateTo(AppDestinations.bottomNav[index].path);
  }

  Future<void> _openMoreSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'More',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rooms, reports and extra tools',
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                ...AppDestinations.more.map((destination) {
                  final selected = destination.path == _currentPath;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surfaceAlt.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _navigateTo(destination.path);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  selected
                                      ? destination.selectedIcon
                                      : destination.icon,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      destination.label,
                                      style: Theme.of(
                                        sheetContext,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      destination.path ==
                                              AppDestinations.rooms.path
                                          ? 'Live inventory and status'
                                          : 'Revenue and occupancy insights',
                                      style: Theme.of(
                                        sheetContext,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.chevron_right_rounded,
                                size: 20,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateTo(String path) {
    if (path == _currentPath) return;
    setState(() => _backStack.add(_currentPath));
    context.go(path);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    if (_backStack.isNotEmpty) {
      final previous = _backStack.removeLast();
      setState(() {});
      context.go(previous);
      return;
    }

    if (_currentPath != AppDestinations.dashboard.path) {
      context.go(AppDestinations.dashboard.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = AppDestinations.all.firstWhere(
      (d) => d.path == _currentPath,
      orElse: () => AppDestinations.dashboard,
    );
    final isDashboard = destination.path == AppDestinations.dashboard.path;

    return PopScope(
      canPop: _atNavigationRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showBackButton) _goBack();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _AppHeader(
                title: destination.label,
                showBrand: isDashboard,
                showBackButton: _showBackButton && !isDashboard,
                onBackTap: _goBack,
                onProfileTap: () =>
                    _navigateTo(AppDestinations.profile.path),
              ),
              Expanded(child: widget.child),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: NavigationBar(
            selectedIndex: _bottomNavIndex(),
            onDestinationSelected: _onBottomNavSelected,
            destinations: [
              ...AppDestinations.bottomNav.map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.shortLabel,
                  tooltip: d.label,
                ),
              ),
              const NavigationDestination(
                icon: Icon(Icons.more_horiz_rounded),
                selectedIcon: Icon(Icons.more_horiz_rounded),
                label: 'More',
                tooltip: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.title,
    required this.showBrand,
    required this.showBackButton,
    required this.onBackTap,
    required this.onProfileTap,
  });

  final String title;
  final bool showBrand;
  final bool showBackButton;
  final VoidCallback onBackTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            _HeaderBackButton(onPressed: onBackTap),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: showBrand
                ? const _BrandBlock()
                : Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
          ),
          IconButton(
            onPressed: () => _showNotifications(context),
            tooltip: 'Notifications',
            visualDensity: VisualDensity.compact,
            icon: Badge(
              label: const Text('2'),
              backgroundColor: AppColors.errorDark,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 2),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onProfileTap,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    StaffProfile.initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const _NotificationRow(
                icon: Icons.cleaning_services_outlined,
                color: AppColors.warningDark,
                title: 'Room 101 cleaning overdue',
                subtitle: 'Housekeeping · 20 minutes ago',
              ),
              const SizedBox(height: 10),
              const _NotificationRow(
                icon: Icons.logout_rounded,
                color: AppColors.infoDark,
                title: 'Check-out due at 11:00 AM',
                subtitle: 'Mathew Hyden · Room 101',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Raintech',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'HOTEL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.6,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Back',
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceAlt,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(40, 40),
        maximumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
    );
  }
}
