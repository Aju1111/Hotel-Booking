import 'package:flutter/material.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/models/booking.dart';
import 'package:hotel_booking/models/room.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/utils/booking_calculator.dart';
import 'package:hotel_booking/utils/formatters.dart';
import 'package:hotel_booking/widgets/page_content.dart';
import 'package:hotel_booking/widgets/room_card.dart';
import 'package:hotel_booking/widgets/ui/app_panel.dart';
import 'package:hotel_booking/widgets/ui/compact_date_picker.dart';
import 'package:hotel_booking/widgets/ui/state_views.dart';
import 'package:hotel_booking/widgets/ui/step_indicator.dart';

class _BookedStayRoom {
  const _BookedStayRoom({
    required this.room,
    required this.checkIn,
    required this.checkOut,
  });

  final HotelRoom room;
  final DateTime checkIn;
  final DateTime checkOut;

  int get nights {
    final start = BookingCalculator.dateOnly(checkIn);
    final end = BookingCalculator.dateOnly(checkOut);
    if (!end.isAfter(start)) return 0;
    return end.difference(start).inDays;
  }

  double get total => room.pricePerNight * nights;
}

/// Core booking screen: pick dates, pick a room, see nights and total price.
class RoomBookingScreen extends StatefulWidget {
  const RoomBookingScreen({super.key});

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  HotelRoom? _selectedRoom;
  int? _guestFilter;
  bool _isSubmitting = false;
  bool _addingAnotherRoom = false;
  String? _successMessage;
  final List<_BookedStayRoom> _confirmedRooms = [];

  List<ExistingBooking> get _allBookings =>
      FrontDeskSession.instance.allBookings;

  bool get _hasStay => _confirmedRooms.isNotEmpty;

  bool get _datesLocked => _hasStay && !_addingAnotherRoom;

  BookingSummary get _summary => BookingCalculator.calculate(
    checkIn: _checkIn,
    checkOut: _checkOut,
    room: _selectedRoom,
    existingBookings: _allBookings,
  );

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    final start = BookingCalculator.dateOnly(_checkIn!);
    final end = BookingCalculator.dateOnly(_checkOut!);
    if (!end.isAfter(start)) return 0;
    return end.difference(start).inDays;
  }

  double get _confirmedTotal =>
      _confirmedRooms.fold<double>(0, (sum, stay) => sum + stay.total);

  double get _stayTotal {
    if (_selectedRoom != null && _summary.isValid) {
      return _confirmedTotal + _summary.totalPrice;
    }
    return _confirmedTotal;
  }

  List<HotelRoom> get _filteredRooms {
    final rooms = FrontDeskSession.instance.rooms;
    if (_guestFilter == null) return rooms;
    return rooms.where((room) => room.maxGuests >= _guestFilter!).toList();
  }

  bool _isRoomBooked(HotelRoom room) {
    if (_checkIn == null || _checkOut == null) return false;
    return !BookingCalculator.isRoomAvailableForDates(
      room: room,
      checkIn: _checkIn!,
      checkOut: _checkOut!,
      existingBookings: _allBookings,
    );
  }

  void _onCheckInPicked(DateTime picked) {
    setState(() {
      _successMessage = null;
      _checkIn = picked;
      if (_checkOut != null && !_checkOut!.isAfter(picked)) {
        _checkOut = picked.add(const Duration(days: 1));
      }
      if (_addingAnotherRoom) _selectedRoom = null;
    });
  }

  void _onCheckOutPicked(DateTime picked) {
    setState(() {
      _successMessage = null;
      _checkOut = picked;
      if (_addingAnotherRoom) _selectedRoom = null;
    });
  }

  Future<void> _confirmBooking() async {
    final summary = _summary;
    if (!summary.isValid || _selectedRoom == null) return;

    final room = _selectedRoom!;
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _addingAnotherRoom = false;
      _selectedRoom = null;
      _confirmedRooms.add(
        _BookedStayRoom(room: room, checkIn: _checkIn!, checkOut: _checkOut!),
      );
      FrontDeskSession.instance.bookRoom(
        room: room,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
      );
      _successMessage =
          '${room.code} booked — '
          '${summary.nights} night(s), '
          '${Formatters.currency.format(summary.totalPrice)}. '
          'Open Check-in and pick ${Formatters.relativeDay(_checkIn!)} to check the guest in.';
    });
  }

  void _startAnotherRoom() {
    setState(() {
      _addingAnotherRoom = true;
      _selectedRoom = null;
      _successMessage =
          'Pick dates and a room for the next booking — dates can differ from the first room.';
    });
  }

  void _startOver() {
    setState(() {
      _checkIn = null;
      _checkOut = null;
      _selectedRoom = null;
      _guestFilter = null;
      _isSubmitting = false;
      _addingAnotherRoom = false;
      _successMessage = null;
      _confirmedRooms.clear();
    });
  }

  bool get _readyToAddAnother =>
      _hasStay && !_addingAnotherRoom && !_isSubmitting;

  String get _actionLabel {
    if (_isSubmitting) return 'Booking…';
    if (_readyToAddAnother) return 'Book another room';
    if (_hasStay) return 'Add this room';
    return 'Confirm booking';
  }

  bool get _actionEnabled {
    if (_isSubmitting) return false;
    if (_readyToAddAnother) return true;
    return _summary.isValid;
  }

  VoidCallback get _onAction {
    if (_readyToAddAnother) return _startAnotherRoom;
    return _confirmBooking;
  }

  int get _activeStep {
    if (_checkIn == null || _checkOut == null) return 0;
    if (_readyToAddAnother) return 2;
    if (_selectedRoom == null) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Column(
      children: [
        Expanded(
          child: PageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StepIndicator(
                  steps: const ['Dates', 'Room', 'Confirm'],
                  currentStep: _activeStep,
                ),
                const SizedBox(height: 16),
                _datesPanel(summary),
                const SizedBox(height: 14),
                _roomsPanel(),
                const SizedBox(height: 14),
                _summaryPanel(),
                if (_successMessage != null) ...[
                  const SizedBox(height: 14),
                  InlineMessage(
                    message: _successMessage!,
                    tone: MessageTone.success,
                  ),
                ],
              ],
            ),
          ),
        ),
        BottomActionBar(
          label: _hasStay
              ? '${_confirmedRooms.length + (_summary.isValid ? 1 : 0)} room(s) · $_nights night(s)'
              : summary.nights > 0
              ? '${summary.nights} night(s) · ${_selectedRoom?.code ?? 'no room'}'
              : 'Select dates & room',
          value: _stayTotal > 0 ? Formatters.currency.format(_stayTotal) : '—',
          actionLabel: _actionLabel,
          enabled: _actionEnabled,
          completed: false,
          onAction: _onAction,
        ),
      ],
    );
  }

  Widget _datesPanel(BookingSummary summary) {
    return AppPanel(
      title: 'Select stay dates',
      subtitle: _datesLocked
          ? 'Dates locked for this stay'
          : _addingAnotherRoom
          ? 'Change dates for the next room if needed'
          : 'Check-out must be after check-in',
      leadingIcon: Icons.date_range_rounded,
      trailing: _hasStay
          ? TextButton(
              onPressed: _startOver,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: const Text('Start over'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) {
              final now = DateTime.now();
              final checkOutFirst =
                  _checkIn?.add(const Duration(days: 1)) ?? now;

              return Row(
                children: [
                  Expanded(
                    child: CompactDateField(
                      label: 'Check-in',
                      value: _checkIn,
                      enabled: !_datesLocked,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                      onPick: _onCheckInPicked,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CompactDateField(
                      label: 'Check-out',
                      value: _checkOut,
                      enabled: !_datesLocked && _checkIn != null,
                      firstDate: checkOutFirst,
                      lastDate: now.add(const Duration(days: 366)),
                      onPick: _onCheckOutPicked,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _guestFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Guests',
              prefixIcon: Icon(Icons.people_outline_rounded, size: 20),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All rooms')),
              DropdownMenuItem(value: 2, child: Text('2+ guests')),
              DropdownMenuItem(value: 3, child: Text('3+ guests')),
              DropdownMenuItem(value: 4, child: Text('4+ guests')),
            ],
            onChanged: (value) => setState(() => _guestFilter = value),
          ),
          const SizedBox(height: 12),
          if (_checkIn == null || _checkOut == null)
            const InlineMessage(
              message: 'Pick both dates to see live availability and pricing.',
            )
          else if (summary.errorMessage != null &&
              !(_hasStay && _selectedRoom == null))
            InlineMessage(
              message: summary.errorMessage!,
              tone: MessageTone.error,
            )
          else
            InlineMessage(
              message: _addingAnotherRoom
                  ? 'Select one more room · $_nights night stay'
                  : '$_nights night stay · ${Formatters.relativeDay(_checkIn!)} → ${Formatters.relativeDay(_checkOut!)}',
              tone: MessageTone.success,
            ),
        ],
      ),
    );
  }

  Widget _roomsPanel() {
    final rooms = _filteredRooms;

    return AppPanel(
      title: 'Available rooms',
      subtitle: _addingAnotherRoom
          ? 'Pick one more room for this stay'
          : 'Tap one room. You can add another after confirming.',
      leadingIcon: Icons.meeting_room_outlined,
      trailing: AppTag(
        label: '${rooms.length}',
        color: AppColors.primary,
        dense: true,
      ),
      padding: const EdgeInsets.all(12),
      child: rooms.isEmpty
          ? EmptyStateView(
              icon: Icons.search_off_rounded,
              title: 'No rooms match this filter',
              message: 'Try lowering the guest count.',
              actionLabel: 'Show all rooms',
              compact: true,
              onAction: () => setState(() => _guestFilter = null),
            )
          : LayoutBuilder(
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
                      child: RoomCard(
                        room: room,
                        isSelected: _selectedRoom?.code == room.code,
                        isBooked: _isRoomBooked(room),
                        onTap: () => setState(() {
                          _selectedRoom = room;
                          if (_addingAnotherRoom) {
                            _successMessage = null;
                          }
                        }),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _summaryPanel() {
    final addingRoom =
        _selectedRoom != null &&
        !_confirmedRooms.any((stay) => stay.room.code == _selectedRoom!.code);

    return AppPanel(
      title: 'Booking summary',
      subtitle: _hasStay
          ? '${_confirmedRooms.length} room(s) in this stay'
          : 'One room now, add another after confirm',
      leadingIcon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_confirmedRooms.isEmpty) ...[
            _SummaryRow(
              label: 'Selected room',
              value: _selectedRoom?.code ?? '—',
            ),
            _SummaryRow(
              label: 'Room type',
              value: _selectedRoom?.roomType ?? '—',
            ),
            _SummaryRow(
              label: 'Price / night',
              value: _selectedRoom == null
                  ? '—'
                  : Formatters.currency.format(_selectedRoom!.pricePerNight),
            ),
          ] else ...[
            for (final stay in _confirmedRooms)
              _SummaryRow(
                label:
                    '${stay.room.code} · ${Formatters.relativeDay(stay.checkIn)}',
                value: stay.nights > 0
                    ? Formatters.currency.format(stay.total)
                    : Formatters.currency.format(stay.room.pricePerNight),
              ),
            if (addingRoom)
              _SummaryRow(
                label: '${_selectedRoom!.code} · adding',
                value: _nights > 0
                    ? Formatters.currency.format(
                        _selectedRoom!.pricePerNight * _nights,
                      )
                    : Formatters.currency.format(_selectedRoom!.pricePerNight),
              ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          if (!_hasStay || _addingAnotherRoom)
            _SummaryRow(
              label: 'Nights (current selection)',
              value: _nights > 0 ? '$_nights' : '—',
              emphasis: true,
            ),
          _SummaryRow(
            label: _hasStay ? 'Stay total' : 'Total price',
            value: _stayTotal > 0
                ? Formatters.currency.format(_stayTotal)
                : '—',
            emphasis: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: emphasis
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: emphasis
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
