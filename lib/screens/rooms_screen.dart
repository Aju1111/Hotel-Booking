import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_booking/app/navigation_destinations.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/models/room.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/utils/formatters.dart';
import 'package:hotel_booking/widgets/page_content.dart';
import 'package:hotel_booking/widgets/room_photo.dart';
import 'package:hotel_booking/widgets/ui/app_panel.dart';
import 'package:hotel_booking/widgets/ui/charts.dart';
import 'package:hotel_booking/widgets/ui/room_action_sheet.dart';
import 'package:hotel_booking/widgets/ui/state_views.dart';
import 'package:hotel_booking/widgets/ui/tiles.dart';

/// Live room inventory with status filters and per-room quick actions.
class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key, this.initialFilter});

  final RoomStatus? initialFilter;

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late RoomStatus? _filter = widget.initialFilter;

  @override
  void didUpdateWidget(covariant RoomsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      _filter = widget.initialFilter;
    }
  }

  List<HotelRoom> get _allRooms => FrontDeskSession.instance.rooms;

  List<HotelRoom> get _rooms => _filter == null
      ? _allRooms
      : _allRooms.where((room) => room.status == _filter).toList();

  int _countWhere(RoomStatus status) =>
      _allRooms.where((room) => room.status == status).length;

  void _changeStatus(HotelRoom room, RoomStatus status) {
    setState(() {
      FrontDeskSession.instance.setRoomStatus(room.roomNumber, status);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${room.code} set to ${roomStatusLabel(status).toLowerCase()}.',
        ),
      ),
    );
  }

  Future<void> _openStatusSheet(HotelRoom room) {
    return showRoomActionSheet(
      context,
      room: room,
      onStatusChanged: (status) => _changeStatus(room, status),
      onBook: () => context.go(AppDestinations.booking.path),
      onCheckIn: () => context.go(AppDestinations.checkIn.path),
      onCheckOut: () => context.go(AppDestinations.checkOut.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _rooms;

    return PageContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPanel(
            title: 'Inventory overview',
            subtitle: '${_allRooms.length} rooms across the property',
            leadingIcon: Icons.apartment_rounded,
            child: StatusBreakdownBar(
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
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterPill(
                  label: 'All (${_allRooms.length})',
                  selected: _filter == null,
                  color: AppColors.primary,
                  onTap: () => setState(() => _filter = null),
                ),
                ...RoomStatus.values.map((status) {
                  return _FilterPill(
                    label:
                        '${roomStatusLabel(status)} (${_countWhere(status)})',
                    selected: _filter == status,
                    color: roomStatusColor(status),
                    onTap: () => setState(() => _filter = status),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (rooms.isEmpty)
            AppPanel(
              child: EmptyStateView(
                icon: Icons.meeting_room_outlined,
                title:
                    'No ${_filter == null ? '' : roomStatusLabel(_filter!).toLowerCase()} rooms',
                message: 'Pick a different filter to see more rooms.',
                actionLabel: 'Show all',
                onAction: () => setState(() => _filter = null),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620 ? 2 : 1;
                const spacing = 10.0;
                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: rooms.map((room) {
                    return SizedBox(
                      width: itemWidth,
                      child: _RoomInventoryCard(
                        room: room,
                        onTap: () => _openStatusSheet(room),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? color.withValues(alpha: 0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomInventoryCard extends StatelessWidget {
  const _RoomInventoryCard({required this.room, required this.onTap});

  final HotelRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (room.imageAsset != null) ...[
                RoomPhoto(imageAsset: room.imageAsset!),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  RoomNumberBadge(roomNumber: room.roomNumber, dense: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      room.roomType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: AppTag(
                      label: roomStatusLabel(room.status),
                      color: roomStatusColor(room.status),
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${Formatters.currency.format(room.pricePerNight)} / night',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.maxGuests}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Floor ${room.floor}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
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
