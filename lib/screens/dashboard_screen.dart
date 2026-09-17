import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_booking/app/navigation_destinations.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/data/staff_profile.dart';
import 'package:hotel_booking/data/sample_data.dart';
import 'package:hotel_booking/models/guest.dart';
import 'package:hotel_booking/models/room.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/utils/formatters.dart';
import 'package:hotel_booking/widgets/page_content.dart';
import 'package:hotel_booking/widgets/ui/app_panel.dart';
import 'package:hotel_booking/widgets/ui/charts.dart';
import 'package:hotel_booking/widgets/ui/dashboard_search_bar.dart';
import 'package:hotel_booking/widgets/ui/floor_plan.dart';
import 'package:hotel_booking/widgets/ui/room_action_sheet.dart';
import 'package:hotel_booking/widgets/ui/state_views.dart';
import 'package:hotel_booking/widgets/ui/stat_card.dart';
import 'package:hotel_booking/widgets/ui/tiles.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _selectedRoomNumber;

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    // Stands in for the property API call the real app would make.
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<HotelRoom> get _rooms => FrontDeskSession.instance.rooms;

  int _countWhere(RoomStatus status) =>
      _rooms.where((r) => r.status == status).length;

  double get _occupancyPercent => _rooms.isEmpty
      ? 0
      : (_countWhere(RoomStatus.occupied) / _rooms.length) * 100;

  List<CheckoutRoom> get _departures =>
      SampleData.checkoutRoomsForGuest('Mathew Hyden');

  double get _revenueToday => SampleData.guestRecords.fold<double>(
    0,
    (sum, guest) => sum + guest.rent + (guest.rent * guest.gstPercent / 100),
  );

  void _go(String path) => context.go(path);

  @override
  Widget build(BuildContext context) {
    return PageContent(
      onRefresh: _load,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GreetingHeader(
            onQuickAction: () => _go(AppDestinations.booking.path),
          ),
          const SizedBox(height: 14),
          if (_loadError != null)
            ErrorStateView(message: _loadError!, onRetry: _load)
          else if (_isLoading)
            const _DashboardSkeleton()
          else ...[
            _occupancyHero(),
            const SizedBox(height: 14),
            _statGrid(),
            const SizedBox(height: 18),
            const SectionLabel(title: 'Quick Actions'),
            _moduleLauncher(),
            const SizedBox(height: 18),
            _floorView(),
            const SizedBox(height: 14),
            _departuresPanel(),
            const SizedBox(height: 14),
            _revenuePanel(),
            const SizedBox(height: 14),
            _quickStatusPanel(),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- hero card

  Widget _occupancyHero() {
    final available = _countWhere(RoomStatus.available);
    final occupied = _countWhere(RoomStatus.occupied);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppColors.raisedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Occupancy today',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_occupancyPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$occupied of ${_rooms.length} rooms occupied',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _HeroRing(percent: _occupancyPercent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(
                label: 'Available',
                value: '$available',
                color: AppColors.roomAvailable,
              ),
              const _HeroDivider(),
              _HeroStat(
                label: 'Departures',
                value: '${_departures.length}',
                color: AppColors.warning,
              ),
              const _HeroDivider(),
              _HeroStat(
                label: 'Needs clean',
                value: '${_countWhere(RoomStatus.dirty)}',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- stat cards

  Widget _statGrid() {
    final cards = [
      StatCard(
        label: 'Pending check-ins',
        value: '${SampleData.guestRecords.length}',
        icon: Icons.login_rounded,
        color: AppColors.successDark,
        caption: 'Today',
        onTap: () => _go(AppDestinations.checkIn.path),
      ),
      StatCard(
        label: 'Pending departures',
        value: '${_departures.length}',
        icon: Icons.logout_rounded,
        color: AppColors.warningDark,
        caption: 'By 11:00 AM',
        onTap: () => _go(AppDestinations.checkOut.path),
      ),
      StatCard(
        label: 'Revenue today',
        value: Formatters.currency.format(_revenueToday),
        icon: Icons.currency_rupee_rounded,
        color: AppColors.accent,
        caption: '+12%',
        onTap: () => _go(AppDestinations.reports.path),
      ),
      StatCard(
        label: 'Rooms ready to sell',
        value: '${_countWhere(RoomStatus.available)}',
        icon: Icons.hotel_rounded,
        color: AppColors.infoDark,
        caption: 'Live',
        onTap: () => _go(AppDestinations.rooms.path),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  height: StatCard.gridHeight,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ----------------------------------------------------------- quick launcher

  Widget _moduleLauncher() {
    final modules = <_Module>[
      _Module(
        'Room Booking',
        Icons.event_available_outlined,
        AppColors.infoDark,
        AppDestinations.booking.path,
      ),
      _Module(
        'Rooms',
        Icons.meeting_room_outlined,
        const Color(0xFF7E57C2),
        AppDestinations.rooms.path,
      ),
      _Module(
        'Check-in',
        Icons.assignment_turned_in_outlined,
        AppColors.successDark,
        AppDestinations.checkIn.path,
      ),
      _Module(
        'Check-out',
        Icons.exit_to_app_rounded,
        AppColors.errorDark,
        AppDestinations.checkOut.path,
      ),
    ];

    return AppPanel(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const columns = 2;
          const spacing = 10.0;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: modules.map((module) {
              return SizedBox(
                width: itemWidth,
                height: ModuleTile.gridHeight,
                child: ModuleTile(
                  label: module.label,
                  icon: module.icon,
                  color: module.color,
                  badge: module.badge,
                  onTap: () => _go(module.path),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------- interactive map

  Widget _floorView() {
    return AppPanel(
      title: 'Room Status',
      subtitle: 'Interactive floor view',
      leadingIcon: Icons.apartment_rounded,
      trailing: AppTag(
        label: '${_rooms.length} rooms',
        color: AppColors.primary,
        dense: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusBreakdownBar(
            segments: [
              (
                'Available',
                _countWhere(RoomStatus.available),
                AppColors.roomAvailable,
              ),
              (
                'Occupied',
                _countWhere(RoomStatus.occupied),
                AppColors.roomOccupied,
              ),
              ('Dirty', _countWhere(RoomStatus.dirty), AppColors.roomDirty),
              (
                'Maintenance',
                _countWhere(RoomStatus.maintenance),
                AppColors.roomMaintenance,
              ),
              (
                'Blocked',
                _countWhere(RoomStatus.blocked),
                AppColors.roomBlocked,
              ),
            ],
          ),
          const SizedBox(height: 14),
          FloorPlanMap(
            rooms: _rooms,
            selectedRoomNumber: _selectedRoomNumber,
            occupancyPercent: _occupancyPercent,
            onRoomTap: _openRoomSheet,
          ),
        ],
      ),
    );
  }

  Future<void> _openRoomSheet(HotelRoom room) async {
    setState(() => _selectedRoomNumber = room.roomNumber);

    await showRoomActionSheet(
      context,
      room: room,
      onStatusChanged: (status) => _applyStatus(room.roomNumber, status),
      onBook: () => _go(AppDestinations.booking.path),
      onCheckIn: () => _go(AppDestinations.checkIn.path),
      onCheckOut: () => _go(AppDestinations.checkOut.path),
    );
  }

  void _applyStatus(int roomNumber, RoomStatus status) {
    setState(() {
      FrontDeskSession.instance.setRoomStatus(roomNumber, status);
      _selectedRoomNumber = roomNumber;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Room $roomNumber marked as ${roomStatusLabel(status).toLowerCase()}.',
        ),
      ),
    );
  }

  // ------------------------------------------------------------- departures

  Widget _departuresPanel() {
    final departures = _departures;

    return AppPanel(
      title: 'Going to Vacate',
      subtitle: 'Rooms departing today',
      leadingIcon: Icons.luggage_outlined,
      trailing: TextButton(
        onPressed: () => _go(AppDestinations.checkOut.path),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: const Text('View all'),
      ),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
      child: departures.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: EmptyStateView(
                icon: Icons.luggage_outlined,
                title: 'No departures today',
                message: 'Every guest is staying another night.',
                compact: true,
              ),
            )
          : SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: departures.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final room = departures[index];

                  return _DepartureCard(
                    roomNumber: room.roomNumber,
                    guestName: 'Mathew Hyden',
                    checkOut: room.checkOut,
                    onTap: () => _go(AppDestinations.checkOut.path),
                  );
                },
              ),
            ),
    );
  }

  // ---------------------------------------------------------------- revenue

  Widget _revenuePanel() {
    const values = [4200.0, 5100.0, 4800.0, 6400.0, 7100.0, 8200.0, 6900.0];
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return AppPanel(
      title: 'Weekly Revenue',
      subtitle: 'Last 7 days',
      leadingIcon: Icons.show_chart_rounded,
      trailing: const AppTag(
        label: '+12%',
        color: AppColors.successDark,
        icon: Icons.trending_up_rounded,
        dense: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MiniBarChart(values: values, labels: labels, highlightIndex: 5),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatRow(
                  label: 'Best day',
                  value: Formatters.currency.format(8200),
                  icon: Icons.emoji_events_outlined,
                  color: AppColors.accent,
                  caption: 'Saturday',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- status changer

  Widget _quickStatusPanel() {
    return AppPanel(
      title: 'Quick Room Status Changer',
      subtitle: 'Housekeeping shortcuts',
      leadingIcon: Icons.auto_fix_high_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selectedRoomNumber,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Room number',
              prefixIcon: Icon(Icons.meeting_room_outlined, size: 20),
            ),
            hint: const Text('Select a room'),
            items: _rooms
                .map(
                  (room) => DropdownMenuItem(
                    value: room.roomNumber,
                    child: Text(
                      'Room ${room.roomNumber} · ${roomStatusLabel(room.status)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedRoomNumber = value),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _selectedRoomNumber == null
                ? null
                : () =>
                      _applyStatus(_selectedRoomNumber!, RoomStatus.available),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.successDark,
            ),
            icon: const Icon(Icons.cleaning_services_rounded, size: 18),
            label: const Text('Cleaning done, ready to serve'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _setAllDirtyToClean,
                  child: const Text(
                    'Clean all dirty',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _go('${AppDestinations.rooms.path}?status=maintenance'),
                  child: const Text(
                    'Maintenance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setAllDirtyToClean() {
    final dirtyRooms = _rooms
        .where((room) => room.status == RoomStatus.dirty)
        .toList();

    if (dirtyRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No dirty rooms right now.')),
      );
      return;
    }

    setState(() {
      for (final room in dirtyRooms) {
        FrontDeskSession.instance.setRoomStatus(
          room.roomNumber,
          RoomStatus.available,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${dirtyRooms.length} room(s) marked ready to serve.'),
      ),
    );
  }
}

// ------------------------------------------------------------------ fragments

class _Module {
  const _Module(this.label, this.icon, this.color, this.path, {this.badge});

  final String label;
  final IconData icon;
  final Color color;
  final String path;
  final String? badge;
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.onQuickAction});

  final VoidCallback onQuickAction;

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Main Dashboard',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(text: '$_timeGreeting, '),
                        TextSpan(
                          text: StaffProfile.firstName.toLowerCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' · '),
                        const TextSpan(
                          text: 'Raintech',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onQuickAction,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Booking'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  Formatters.dateTime.format(now),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const DashboardSearchBar(),
      ],
    );
  }
}

class _HeroRing extends StatelessWidget {
  const _HeroRing({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: percent.clamp(0, 100) / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 74,
          height: 74,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.accentLight,
                  ),
                ),
              ),
              const Icon(
                Icons.apartment_rounded,
                color: Colors.white,
                size: 26,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({
    required this.roomNumber,
    required this.guestName,
    required this.checkOut,
    required this.onTap,
  });

  final int roomNumber;
  final String guestName;
  final DateTime checkOut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          width: 186,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  RoomNumberBadge(roomNumber: roomNumber, dense: true),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: AppTag(
                      label: 'Departing',
                      color: AppColors.warningDark,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                guestName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Check-out ${Formatters.date.format(checkOut)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '11:00 AM',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SkeletonBox(height: 168, radius: AppTheme.radiusXl),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(
              child: SkeletonBox(
                height: StatCard.gridHeight,
                radius: AppTheme.radiusLg,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: SkeletonBox(
                height: StatCard.gridHeight,
                radius: AppTheme.radiusLg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: SkeletonBox(
                height: StatCard.gridHeight,
                radius: AppTheme.radiusLg,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: SkeletonBox(
                height: StatCard.gridHeight,
                radius: AppTheme.radiusLg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SkeletonBox(height: 190, radius: AppTheme.radiusLg),
        const SizedBox(height: 14),
        const SkeletonBox(height: 220, radius: AppTheme.radiusLg),
      ],
    );
  }
}
