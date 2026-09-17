import 'package:flutter/material.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/models/guest.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/utils/booking_calculator.dart';
import 'package:hotel_booking/utils/formatters.dart';
import 'package:hotel_booking/widgets/page_content.dart';
import 'package:hotel_booking/widgets/ui/app_panel.dart';
import 'package:hotel_booking/widgets/ui/compact_date_picker.dart';
import 'package:hotel_booking/widgets/ui/compact_time_picker.dart';
import 'package:hotel_booking/widgets/ui/state_views.dart';
import 'package:hotel_booking/widgets/ui/step_indicator.dart';
import 'package:hotel_booking/widgets/ui/tiles.dart';

/// Departure flow: identify the guest, finalise the folio, take payment.
/// Mirrors the desktop three-column reference as a phone stepper.
class GuestCheckoutScreen extends StatefulWidget {
  const GuestCheckoutScreen({super.key});

  @override
  State<GuestCheckoutScreen> createState() => _GuestCheckoutScreenState();
}

class _GuestCheckoutScreenState extends State<GuestCheckoutScreen> {
  static const _steps = ['Identify', 'Review bill', 'Payment'];
  static const _paymentMethods = ['Credit Card', 'Cash', 'M-Pay'];

  final _roomSearchController = TextEditingController(text: '101');
  final _paymentController = TextEditingController();

  int _currentStep = 0;
  String _selectedGuest = 'Mathew Hyden';
  String _paymentMethod = 'Credit Card';
  DateTime _checkInDate = Formatters.today;
  TimeOfDay _checkInTime = const TimeOfDay(hour: 19, minute: 0);
  List<CheckoutRoom> _rooms = [];

  /// Charges added from this screen, keyed by room number.
  final Map<int, List<RoomCharge>> _addedCharges = {};

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _checkOutCompleted = false;
  String? _successMessage;
  String? _selectionError;

  @override
  void initState() {
    super.initState();
    _loadRooms(initial: true);
  }

  @override
  void dispose() {
    _roomSearchController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms({bool initial = false}) async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(Duration(milliseconds: initial ? 500 : 400));
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _addedCharges.clear();
      _selectionError = null;
      _isProcessing = false;
      _showNextDepartingGuest(clearSuccess: initial);
      _syncPaymentAmount();
    });
  }

  void _syncPaymentAmount() {
    _paymentController.text = _combinedTotal.toStringAsFixed(2);
  }

  List<RoomCharge> _chargesFor(CheckoutRoom room) => [
    ...room.charges,
    ...?_addedCharges[room.roomNumber],
  ];

  double _totalFor(CheckoutRoom room) =>
      room.roomTotal +
      _chargesFor(room).fold<double>(0, (sum, c) => sum + c.amount);

  List<CheckoutRoom> get _selectedRooms =>
      _rooms.where((room) => room.selectedForCheckout).toList();

  double get _combinedTotal =>
      _selectedRooms.fold<double>(0, (sum, room) => sum + _totalFor(room));

  List<CheckoutRoom> _filterRoomsByCheckInDate(List<CheckoutRoom> rooms) {
    final target = BookingCalculator.dateOnly(_checkInDate);
    return rooms
        .where(
          (room) => BookingCalculator.dateOnly(room.checkIn) == target,
        )
        .toList();
  }

  List<String> get _guestsForSelectedCheckInDate =>
      FrontDeskSession.instance.departingGuestsForCheckInDate(_checkInDate);

  void _refreshRoomsForGuest() {
    _rooms = _filterRoomsByCheckInDate(
      FrontDeskSession.instance.remainingRoomsFor(_selectedGuest),
    );
    _syncPaymentAmount();
  }

  void _onCheckInDatePicked(DateTime date) {
    setState(() {
      _checkInDate = date;
      _selectionError = null;
      final guests = _guestsForSelectedCheckInDate;
      if (guests.isEmpty) {
        _rooms = [];
        return;
      }
      if (!guests.contains(_selectedGuest)) {
        _selectedGuest = guests.first;
      }
      _refreshRoomsForGuest();
    });
  }

  void _toggleRoom(int roomNumber, bool selected) {
    setState(() {
      _rooms = _rooms
          .map(
            (room) => room.roomNumber == roomNumber
                ? room.copyWith(selectedForCheckout: selected)
                : room,
          )
          .toList();
      _selectionError = null;
      _syncPaymentAmount();
    });
  }

  void _addCharge(int roomNumber, String description, double amount) {
    setState(() {
      _addedCharges
          .putIfAbsent(roomNumber, () => [])
          .add(
            RoomCharge(
              description: description,
              date: DateTime.now(),
              amount: amount,
            ),
          );
      _syncPaymentAmount();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$description added to room $roomNumber.')),
    );
  }

  void _toggleCharge(int roomNumber, String description, double amount) {
    final extras = _addedCharges[roomNumber];
    final index =
        extras?.indexWhere((charge) => charge.description == description) ?? -1;

    if (index >= 0) {
      setState(() {
        extras!.removeAt(index);
        if (extras.isEmpty) _addedCharges.remove(roomNumber);
        _syncPaymentAmount();
      });
      return;
    }

    _addCharge(roomNumber, description, amount);
  }

  Future<void> _completeCheckout({required bool combined}) async {
    if (_checkOutCompleted || _isProcessing) return;

    if (_selectedRooms.isEmpty) {
      setState(
        () => _selectionError = 'Select at least one room to check out.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _selectionError = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final rooms = _selectedRooms.map((r) => r.roomNumber).join(', ');
    FrontDeskSession.instance.completeCheckout(
      guestName: _selectedGuest,
      roomNumbers: _selectedRooms.map((room) => room.roomNumber),
    );
    setState(() {
      _isProcessing = false;
      _checkOutCompleted = true;
      _currentStep = 2;
      _successMessage = combined
          ? 'Combined check-out completed for rooms $rooms via $_paymentMethod.'
          : 'Check-out completed for room ${_selectedRooms.first.roomNumber} via $_paymentMethod.';
    });
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
      if (step < 2 && _checkOutCompleted) {
        _checkOutCompleted = false;
        _showNextDepartingGuest();
      }
    });
  }

  void _showNextDepartingGuest({bool clearSuccess = false}) {
    final remaining = _guestsForSelectedCheckInDate;
    if (remaining.isEmpty) {
      _rooms = [];
      if (clearSuccess) _successMessage = null;
      _checkOutCompleted = false;
      return;
    }

    if (!remaining.contains(_selectedGuest)) {
      _selectedGuest = remaining.first;
    }
    _refreshRoomsForGuest();
    _addedCharges.clear();
    _checkOutCompleted = false;
    if (clearSuccess) _successMessage = null;
  }

  void _findByRoom() {
    final roomNumber = int.tryParse(_roomSearchController.text.trim());
    if (roomNumber == null) return;

    final guest = FrontDeskSession.instance.guestForRoom(roomNumber);
    if (guest == null) {
      setState(
        () => _selectionError =
            'Room $roomNumber is not checked in yet. Complete check-in first.',
      );
      return;
    }

    final matching = _filterRoomsByCheckInDate(
      FrontDeskSession.instance.remainingRoomsFor(guest),
    );

    setState(() {
      _selectedGuest = guest;
      _rooms = matching;
      _selectionError = matching.any((room) => room.roomNumber == roomNumber)
          ? null
          : 'Room $roomNumber was checked in on a different date.';
      _syncPaymentAmount();
    });
  }

  void _notify(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageContent(
            onRefresh: _loadRooms,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StepIndicator(
                  steps: _steps,
                  currentStep: _currentStep,
                  onStepTapped: _goToStep,
                ),
                const SizedBox(height: 16),
                if (_successMessage != null) ...[
                  InlineMessage(
                    message: _successMessage!,
                    tone: MessageTone.success,
                  ),
                  const SizedBox(height: 14),
                ],
                if (_isLoading)
                  const AppPanel(child: PanelLoadingState(lines: 4))
                else
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: switch (_currentStep) {
                      0 => _identifyStep(),
                      1 => _billStep(),
                      _ => _paymentStep(),
                    },
                  ),
              ],
            ),
          ),
        ),
        BottomActionBar(
          label: _checkOutCompleted
              ? 'Checked out'
              : '${_selectedRooms.length} room(s) selected',
          value: Formatters.currency.format(_combinedTotal),
          actionLabel: _currentStep != 2
              ? 'Continue'
              : _isProcessing
              ? 'Processing…'
              : _checkOutCompleted
              ? 'Checked out'
              : 'Check out',
          actionIcon: _currentStep == 2
              ? (_checkOutCompleted
                    ? Icons.check_circle_rounded
                    : Icons.logout_rounded)
              : null,
          completed: _currentStep == 2 && _checkOutCompleted,
          enabled: !_isProcessing && !(_currentStep == 2 && _checkOutCompleted),
          onAction: _currentStep == 2
              ? () => _completeCheckout(combined: _selectedRooms.length > 1)
              : () => _goToStep(_currentStep + 1),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- step 1

  Widget _identifyStep() {
    final checkedIn = FrontDeskSession.instance.departingGuests;
    final guestsForDate = _guestsForSelectedCheckInDate;
    final guestValue = guestsForDate.contains(_selectedGuest)
        ? _selectedGuest
        : (guestsForDate.isEmpty ? _selectedGuest : guestsForDate.first);

    return AppPanel(
      key: const ValueKey('checkout-identify'),
      title: 'Identify departing guest',
      subtitle: 'Checked-in rooms only — filter by check-in date',
      leadingIcon: Icons.person_search_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (checkedIn.isEmpty)
            const EmptyStateView(
              icon: Icons.person_off_outlined,
              title: 'No checked-in guests',
              message:
                  'Complete check-in first. Only checked-in rooms appear here.',
              compact: true,
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: CompactDateField(
                    label: 'Check-in date',
                    value: _checkInDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                    onPick: _onCheckInDatePicked,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CompactTimeField(
                    label: 'Check-in time',
                    value: _checkInTime,
                    onPick: (time) => setState(() => _checkInTime = time),
                  ),
                ),
              ],
            ),
            if (guestsForDate.isNotEmpty) ...[
              const SizedBox(height: 10),
              InlineMessage(
                message:
                    '${_rooms.length} checked-in room(s) on '
                    '${Formatters.relativeDay(_checkInDate)}',
                    tone: MessageTone.success,
              ),
            ],
            const SizedBox(height: 12),
            if (guestsForDate.isEmpty)
              EmptyStateView(
                icon: Icons.event_busy_rounded,
                title: 'No check-ins on this date',
                message:
                    'Pick another date or check guests in from the Check-in tab.',
                compact: true,
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey('$guestValue-${_checkInDate.millisecondsSinceEpoch}'),
                initialValue: guestValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select guest',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                items: guestsForDate
                    .map(
                      (guest) => DropdownMenuItem(
                        value: guest,
                        child: Text(guest, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedGuest = value;
                    _refreshRoomsForGuest();
                  });
                },
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _roomSearchController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Identify by room',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _findByRoom,
                    child: const Text('Find'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (checkedIn.isEmpty)
            const SizedBox.shrink()
          else if (guestsForDate.isEmpty)
            const SizedBox.shrink()
          else if (_rooms.isEmpty)
            EmptyStateView(
              icon: Icons.meeting_room_outlined,
              title: 'No rooms for this check-in',
              message:
                  '$_selectedGuest has no checked-in rooms on '
                  '${Formatters.relativeDay(_checkInDate)}.',
              actionLabel: 'Reload',
              compact: true,
              onAction: _loadRooms,
            )
          else if (guestsForDate.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedGuest.substring(0, 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedGuest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_rooms.length} room(s) on this folio',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._rooms.map((room) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RoomSelectRow(
                  room: room,
                  total: _totalFor(room),
                  onChanged: (value) => _toggleRoom(room.roomNumber, value),
                ),
              );
            }),
            if (_selectionError != null) ...[
              const SizedBox(height: 6),
              InlineMessage(
                message: _selectionError!,
                tone: MessageTone.warning,
              ),
            ],
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => _notify('Room picker coming from PMS sync.'),
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              label: const Text('Add / change selected rooms'),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------- step 2

  Widget _billStep() {
    final selected = _selectedRooms;

    if (selected.isEmpty) {
      return AppPanel(
        key: const ValueKey('checkout-bill-empty'),
        title: 'Review & finalize bill',
        leadingIcon: Icons.receipt_long_outlined,
        child: EmptyStateView(
          icon: Icons.receipt_long_outlined,
          title: 'No rooms selected',
          message: 'Go back to step 1 and select the departing rooms.',
          actionLabel: 'Back to step 1',
          compact: true,
          onAction: () => _goToStep(0),
        ),
      );
    }

    return Column(
      key: const ValueKey('checkout-bill'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...selected.map(
          (room) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RoomBillPanel(
              room: room,
              charges: _chargesFor(room),
              total: _totalFor(room),
              selectedExtras: {
                for (final charge in _addedCharges[room.roomNumber] ?? [])
                  charge.description,
              },
              onToggleCharge: (description, amount) =>
                  _toggleCharge(room.roomNumber, description, amount),
              onPrint: () => _notify(
                'Invoice for room ${room.roomNumber} sent to printer.',
              ),
              onAdjust: () =>
                  _notify('Adjust charges for room ${room.roomNumber}.'),
            ),
          ),
        ),
        AppPanel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Selected rooms combined total',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.currency.format(_combinedTotal),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- step 3

  Widget _paymentStep() {
    return AppPanel(
      key: const ValueKey('checkout-payment'),
      title: 'Payment & check-out',
      subtitle: '${_selectedRooms.length} room(s) selected',
      leadingIcon: Icons.credit_card_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total amount due',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Formatters.currency.format(_combinedTotal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Payment method', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: _paymentMethods.map((method) {
              final selected = method == _paymentMethod;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: _checkOutCompleted
                        ? null
                        : () => setState(() => _paymentMethod = method),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.09)
                            : AppColors.surfaceAlt.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            switch (method) {
                              'Cash' => Icons.payments_outlined,
                              'M-Pay' => Icons.qr_code_rounded,
                              _ => Icons.credit_card_rounded,
                            },
                            size: 19,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            method,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _paymentController,
            enabled: !_checkOutCompleted,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Payment amount',
              prefixText: '₹ ',
            ),
          ),
          if (_selectionError != null) ...[
            const SizedBox(height: 12),
            InlineMessage(message: _selectionError!, tone: MessageTone.warning),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _checkOutCompleted || _isProcessing
                ? null
                : () => _completeCheckout(combined: false),
            style: FilledButton.styleFrom(
              backgroundColor: _checkOutCompleted
                  ? AppColors.successDark
                  : AppColors.primary,
              disabledBackgroundColor: _checkOutCompleted
                  ? AppColors.successDark
                  : AppColors.primary.withValues(alpha: 0.45),
              disabledForegroundColor: Colors.white,
            ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _checkOutCompleted
                        ? Icons.check_circle_rounded
                        : Icons.task_alt_rounded,
                    size: 18,
                  ),
            label: Text(
              _isProcessing
                  ? 'Processing…'
                  : _checkOutCompleted
                  ? 'Checked out'
                  : 'Process payment & check-out',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _checkOutCompleted || _isProcessing
                ? null
                : () => _completeCheckout(combined: true),
            icon: Icon(
              _checkOutCompleted
                  ? Icons.check_circle_outline_rounded
                  : Icons.merge_rounded,
              size: 17,
            ),
            label: Text(
              _checkOutCompleted ? 'Checked out' : 'Combined check-out',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _notify('Final invoice sent to printer.'),
                  icon: const Icon(Icons.print_outlined, size: 17),
                  label: const Text(
                    'Print',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _notify('Final invoice emailed to guest.'),
                  icon: const Icon(Icons.mail_outline_rounded, size: 17),
                  label: const Text(
                    'Email',
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
}

// ---------------------------------------------------------------- fragments

class _RoomSelectRow extends StatelessWidget {
  const _RoomSelectRow({
    required this.room,
    required this.total,
    required this.onChanged,
  });

  final CheckoutRoom room;
  final double total;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = room.selectedForCheckout;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.06)
          : AppColors.surfaceAlt.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        RoomNumberBadge(
                          roomNumber: room.roomNumber,
                          dense: true,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            Formatters.currency.format(total),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${Formatters.relativeDay(room.checkIn)} – ${Formatters.relativeDay(room.checkOut)} · ${room.nights} nights',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomBillPanel extends StatelessWidget {
  const _RoomBillPanel({
    required this.room,
    required this.charges,
    required this.total,
    required this.selectedExtras,
    required this.onToggleCharge,
    required this.onPrint,
    required this.onAdjust,
  });

  final CheckoutRoom room;
  final List<RoomCharge> charges;
  final double total;
  final Set<String> selectedExtras;
  final void Function(String description, double amount) onToggleCharge;
  final VoidCallback onPrint;
  final VoidCallback onAdjust;

  static const _extras = [
    (label: 'Mini-bar', icon: Icons.local_bar_outlined, amount: 100.0),
    (
      label: 'Laundry',
      icon: Icons.local_laundry_service_outlined,
      amount: 250.0,
    ),
    (label: 'Room service', icon: Icons.room_service_outlined, amount: 450.0),
  ];

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Room ${room.roomNumber}',
      subtitle:
          '${room.nights} nights · ${Formatters.currency.format(room.ratePerNight)}/night · ${Formatters.currency.format(room.roomTotal)}',
      leadingIcon: Icons.bed_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add items', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final extra in _extras)
                _AddItemChip(
                  label: extra.label,
                  icon: extra.icon,
                  selected: selectedExtras.contains(extra.label),
                  onSelected: () => onToggleCharge(extra.label, extra.amount),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (charges.isEmpty)
            const EmptyStateView(
              icon: Icons.receipt_outlined,
              title: 'No extra charges',
              compact: true,
            )
          else
            ...charges.map(
              (charge) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            charge.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            Formatters.date.format(charge.date),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.currency.format(charge.amount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Room ${room.roomNumber} total',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.currency.format(total),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPrint,
                  icon: const Icon(Icons.print_outlined, size: 17),
                  label: const Text(
                    'Invoice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAdjust,
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: const Text(
                    'Adjust',
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
}

class _AddItemChip extends StatelessWidget {
  const _AddItemChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.primary;

    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(icon, size: 15, color: foreground),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      backgroundColor: AppColors.surfaceAlt,
      selectedColor: AppColors.primary,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      onSelected: (_) => onSelected(),
    );
  }
}
