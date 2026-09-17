import 'package:flutter/material.dart';
import 'package:hotel_booking/models/room.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/widgets/ui/tiles.dart';

/// PMS-style floor map: rooms on both sides of a corridor, like a real wing.
class FloorPlanMap extends StatelessWidget {
  const FloorPlanMap({
    super.key,
    required this.rooms,
    required this.selectedRoomNumber,
    required this.onRoomTap,
    required this.occupancyPercent,
  });

  final List<HotelRoom> rooms;
  final int? selectedRoomNumber;
  final ValueChanged<HotelRoom> onRoomTap;
  final double occupancyPercent;

  @override
  Widget build(BuildContext context) {
    final floors = <int, List<HotelRoom>>{};
    for (final room in rooms) {
      floors.putIfAbsent(room.floor, () => []).add(room);
    }
    final floorNumbers = floors.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlanHeader(total: rooms.length, occupancyPercent: occupancyPercent),
        const SizedBox(height: 14),
        ...floorNumbers.map((floor) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _FloorWing(
              floor: floor,
              rooms: floors[floor]!,
              selectedRoomNumber: selectedRoomNumber,
              onRoomTap: onRoomTap,
            ),
          );
        }),
        const _StatusLegend(),
      ],
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.total, required this.occupancyPercent});

  final int total;
  final double occupancyPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.map_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$total rooms  ·  ${occupancyPercent.toStringAsFixed(0)}% occupied',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tap a key to inspect guest, HK status or block the room.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorWing extends StatelessWidget {
  const _FloorWing({
    required this.floor,
    required this.rooms,
    required this.selectedRoomNumber,
    required this.onRoomTap,
  });

  final int floor;
  final List<HotelRoom> rooms;
  final int? selectedRoomNumber;
  final ValueChanged<HotelRoom> onRoomTap;

  @override
  Widget build(BuildContext context) {
    final sorted = [...rooms]
      ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'FLOOR $floor',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoomBank(
                  rooms: sorted,
                  selectedRoomNumber: selectedRoomNumber,
                  onRoomTap: onRoomTap,
                ),
                const SizedBox(height: 6),
                const _Corridor(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Corridor extends StatelessWidget {
  const _Corridor();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cream.withValues(alpha: 0.4),
            AppColors.cream,
            AppColors.cream.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _serviceMark(Icons.elevator_outlined),
          const Spacer(),
          Text(
            'CORRIDOR',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          _serviceMark(Icons.stairs_outlined),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _serviceMark(IconData icon) {
    return Icon(icon, size: 12, color: AppColors.textSecondary);
  }
}

class _RoomBank extends StatelessWidget {
  const _RoomBank({
    required this.rooms,
    required this.selectedRoomNumber,
    required this.onRoomTap,
  });

  final List<HotelRoom> rooms;
  final int? selectedRoomNumber;
  final ValueChanged<HotelRoom> onRoomTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < rooms.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          SizedBox(
            width: 52,
            child: RoomStatusTile(
              roomNumber: rooms[i].roomNumber,
              status: rooms[i].status,
              selected: selectedRoomNumber == rooms[i].roomNumber,
              size: 48,
              fillWidth: true,
              onTap: () => onRoomTap(rooms[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    const items = [
      (RoomStatus.available, 'Available'),
      (RoomStatus.occupied, 'Occupied'),
      (RoomStatus.dirty, 'Dirty'),
      (RoomStatus.maintenance, 'Maint.'),
      (RoomStatus.blocked, 'Blocked'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: roomStatusColor(item.$1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 5),
            Text(item.$2, style: Theme.of(context).textTheme.labelSmall),
          ],
        );
      }).toList(),
    );
  }
}
