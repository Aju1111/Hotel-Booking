import 'package:flutter/material.dart';
import 'package:hotel_booking/data/sample_data.dart';
import 'package:hotel_booking/models/room.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/utils/formatters.dart';
import 'package:hotel_booking/widgets/ui/app_panel.dart';
import 'package:hotel_booking/widgets/ui/tiles.dart';

Future<void> showRoomActionSheet(
  BuildContext context, {
  required HotelRoom room,
  required ValueChanged<RoomStatus> onStatusChanged,
  VoidCallback? onBook,
  VoidCallback? onCheckIn,
  VoidCallback? onCheckOut,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.75;
      final ticket = SampleData.ticketFor(room.roomNumber);

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    RoomNumberBadge(roomNumber: room.roomNumber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${room.code} · ${room.roomType}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(sheetContext).textTheme.titleMedium,
                          ),
                          Text(
                            '${Formatters.currency.format(room.pricePerNight)} / night · Floor ${room.floor}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(sheetContext).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    AppTag(
                      label: roomStatusLabel(room.status),
                      color: roomStatusColor(room.status),
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _statusLogic(
                  sheetContext,
                  room: room,
                  ticket: ticket,
                ),
                const SizedBox(height: 12),
                ..._primaryActions(
                  sheetContext,
                  room: room,
                  onStatusChanged: onStatusChanged,
                  onBook: onBook,
                  onCheckIn: onCheckIn,
                  onCheckOut: onCheckOut,
                ),
                const SizedBox(height: 16),
                Text(
                  'Change status',
                  style: Theme.of(sheetContext).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RoomStatus.values.map((status) {
                    final selected = status == room.status;

                    return ChoiceChip(
                      label: Text(roomStatusLabel(status)),
                      selected: selected,
                      avatar: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: roomStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      selectedColor: roomStatusColor(
                        status,
                      ).withValues(alpha: 0.2),
                      onSelected: (_) {
                        Navigator.of(sheetContext).pop();
                        onStatusChanged(status);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _statusLogic(
  BuildContext context, {
  required HotelRoom room,
  required MaintenanceTicket ticket,
}) {
  final (icon, title, message) = switch (room.status) {
    RoomStatus.maintenance => (
      Icons.handyman_outlined,
      ticket.issue,
      '${ticket.technician} · ETA ${ticket.eta}',
    ),
    RoomStatus.dirty => (
      Icons.cleaning_services_outlined,
      'Housekeeping pending',
      'Room is vacant and waiting to be cleaned before it can be sold.',
    ),
    RoomStatus.occupied => (
      Icons.person_outline_rounded,
      'Guest in-house',
      'This room is occupied. Use check-out when the guest is ready to leave.',
    ),
    RoomStatus.blocked => (
      Icons.block_rounded,
      'Room blocked',
      'This room is held out of inventory. Unblock it to sell again.',
    ),
    RoomStatus.available => (
      Icons.check_circle_outline_rounded,
      'Ready to sell',
      'This room is vacant, clean, and available for booking or check-in.',
    ),
  };

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: roomStatusColor(room.status).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(
        color: roomStatusColor(room.status).withValues(alpha: 0.28),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: roomStatusColor(room.status)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(message, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

List<Widget> _primaryActions(
  BuildContext sheetContext, {
  required HotelRoom room,
  required ValueChanged<RoomStatus> onStatusChanged,
  VoidCallback? onBook,
  VoidCallback? onCheckIn,
  VoidCallback? onCheckOut,
}) {
  void closeThen(VoidCallback? action) {
    Navigator.of(sheetContext).pop();
    action?.call();
  }

  return switch (room.status) {
    RoomStatus.maintenance => [
      FilledButton.icon(
        onPressed: () {
          Navigator.of(sheetContext).pop();
          onStatusChanged(RoomStatus.available);
        },
        icon: const Icon(Icons.task_alt_rounded, size: 18),
        label: const Text('Work done, ready to sell'),
      ),
    ],
    RoomStatus.dirty => [
      FilledButton.icon(
        onPressed: () {
          Navigator.of(sheetContext).pop();
          onStatusChanged(RoomStatus.available);
        },
        style: FilledButton.styleFrom(backgroundColor: AppColors.successDark),
        icon: const Icon(Icons.cleaning_services_rounded, size: 18),
        label: const Text('Cleaning done, ready to serve'),
      ),
    ],
    RoomStatus.occupied => [
      FilledButton.icon(
        onPressed: onCheckOut == null ? null : () => closeThen(onCheckOut),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Check out guest'),
      ),
    ],
    RoomStatus.blocked => [
      FilledButton.icon(
        onPressed: () {
          Navigator.of(sheetContext).pop();
          onStatusChanged(RoomStatus.available);
        },
        icon: const Icon(Icons.lock_open_rounded, size: 18),
        label: const Text('Unblock room'),
      ),
    ],
    RoomStatus.available => [
      FilledButton.icon(
        onPressed: onBook == null ? null : () => closeThen(onBook),
        icon: const Icon(Icons.event_available_outlined, size: 18),
        label: const Text('Book this room'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: onCheckIn == null ? null : () => closeThen(onCheckIn),
        icon: const Icon(Icons.login_rounded, size: 18),
        label: const Text('Check in a guest'),
      ),
    ],
  };
}
