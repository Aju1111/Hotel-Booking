import 'package:flutter/material.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/models/guest.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/utils/formatters.dart';
import 'package:hotel_booking/widgets/page_content.dart';
import 'package:hotel_booking/widgets/ui/app_panel.dart';
import 'package:hotel_booking/widgets/ui/compact_date_picker.dart';
import 'package:hotel_booking/widgets/ui/compact_time_picker.dart';
import 'package:hotel_booking/widgets/ui/state_views.dart';
import 'package:hotel_booking/widgets/ui/step_indicator.dart';
import 'package:hotel_booking/widgets/ui/tiles.dart';

/// Guest arrival flow. The desktop reference uses three side-by-side columns;
/// on a phone the same three stages become a stepper with a sticky total bar.
class GuestCheckinScreen extends StatefulWidget {
  const GuestCheckinScreen({super.key});

  @override
  State<GuestCheckinScreen> createState() => _GuestCheckinScreenState();
}

class _GuestCheckinScreenState extends State<GuestCheckinScreen> {
  static const _steps = ['Find guest', 'Review details', 'Payment'];

  final _searchController = TextEditingController();
  final _rentController = TextEditingController(text: '1200');
  final _gstController = TextEditingController(text: '12');
  final _adultsController = TextEditingController(text: '02');
  final _kidsController = TextEditingController(text: '00');
  final _guestNameController = TextEditingController(text: 'Mathew Hyden');

  int _currentStep = 0;
  String? _selectedGuest;
  GuestRecord? _activeRecord;
  DateTime _bookingDate = Formatters.today;
  TimeOfDay _bookingTime = const TimeOfDay(hour: 19, minute: 0);
  DateTime _checkoutDate = DateTime(2026, 4, 4);
  String? _idProofName;
  bool _isSearching = false;
  bool _isCompleting = false;
  bool _checkInCompleted = false;
  String? _searchError;
  String? _nameError;

  @override
  void dispose() {
    _searchController.dispose();
    _rentController.dispose();
    _gstController.dispose();
    _adultsController.dispose();
    _kidsController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  List<GuestRecord> get _filteredRecords {
    final pending = FrontDeskSession.instance.pendingCheckInRecords(
      checkInDate: _bookingDate,
    );
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return pending;

    return pending.where((record) {
      return record.guestName.toLowerCase().contains(query) ||
          record.bookingId.toLowerCase().contains(query) ||
          record.roomNumber.toString().contains(query);
    }).toList();
  }

  double get _roomCharge => double.tryParse(_rentController.text) ?? 0;
  double get _extraCharges => 200;
  double get _tax =>
      (_roomCharge + _extraCharges) *
      (double.tryParse(_gstController.text) ?? 0) /
      100;
  double get _total => _roomCharge + _extraCharges + _tax;

  Future<void> _findGuest() async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final records = _filteredRecords;
    setState(() {
      _isSearching = false;
      if (records.isEmpty) {
        _activeRecord = null;
        _searchError = 'No booking matches "${_searchController.text.trim()}".';
      } else {
        _applyRecord(records.first);
        _currentStep = 1;
      }
    });
  }

  void _applyRecord(GuestRecord record) {
    _activeRecord = record;
    _selectedGuest = record.guestName;
    _guestNameController.text = record.guestName;
    _rentController.text = record.rent.toStringAsFixed(0);
    _gstController.text = record.gstPercent.toStringAsFixed(0);
    _adultsController.text = record.adults.toString().padLeft(2, '0');
    _kidsController.text = record.kids.toString().padLeft(2, '0');
    _bookingDate = record.checkInDate;
    _bookingTime = const TimeOfDay(hour: 19, minute: 0);
    _checkoutDate = record.checkoutDate;
    _idProofName = record.idProof;
    _nameError = null;
    _checkInCompleted = false;
    _isCompleting = false;
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
      if (step < 2) _checkInCompleted = false;
    });
  }

  Future<void> _completeCheckIn() async {
    if (_checkInCompleted || _isCompleting) return;

    if (_guestNameController.text.trim().isEmpty) {
      setState(() {
        _nameError = 'Guest name is required.';
        _currentStep = 1;
      });
      return;
    }

    setState(() {
      _nameError = null;
      _isCompleting = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final record = _activeRecord;
    if (record != null) {
      FrontDeskSession.instance.completeCheckIn(
        record: record,
        checkInDate: _bookingDate,
        checkOutDate: _checkoutDate,
      );
    }

    setState(() {
      _isCompleting = false;
      _checkInCompleted = true;
      _activeRecord = null;
      _selectedGuest = null;
      _currentStep = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.successDark,
        content: Text(
          'Check-in completed for ${_guestNameController.text.trim()}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StepIndicator(
                  steps: _steps,
                  currentStep: _currentStep,
                  onStepTapped: _goToStep,
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: switch (_currentStep) {
                    0 => _findGuestStep(),
                    1 => _reviewStep(),
                    _ => _paymentStep(),
                  },
                ),
                const SizedBox(height: 14),
                _guestList(),
              ],
            ),
          ),
        ),
        BottomActionBar(
          label: _checkInCompleted ? 'Checked in' : 'Total amount',
          value: Formatters.currency.format(_total),
          actionLabel: _currentStep != 2
              ? 'Continue'
              : _isCompleting
              ? 'Completing…'
              : _checkInCompleted
              ? 'Checked in'
              : 'Complete check-in',
          actionIcon: _currentStep == 2
              ? (_checkInCompleted
                    ? Icons.check_circle_rounded
                    : Icons.how_to_reg_rounded)
              : null,
          completed: _currentStep == 2 && _checkInCompleted,
          enabled: !_isCompleting && !(_currentStep == 2 && _checkInCompleted),
          onAction: _currentStep == 2
              ? _completeCheckIn
              : () => _goToStep(_currentStep + 1),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- step 1

  Widget _findGuestStep() {
    return AppPanel(
      key: const ValueKey('step-find'),
      title: 'Select booking & guest',
      subtitle: 'Booked rooms only — pick check-in date to filter',
      leadingIcon: Icons.person_search_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Booking ID / guest name',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
            onChanged: (_) => setState(() => _searchError = null),
            onSubmitted: (_) => _findGuest(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedGuest,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select customer',
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
            ),
            hint: const Text('Name / phone number'),
            items: _filteredRecords
                .map((record) => record.guestName)
                .toSet()
                .map(
                  (guest) => DropdownMenuItem(
                    value: guest,
                    child: Text(guest, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedGuest = value;
                _guestNameController.text = value ?? '';
                _nameError = null;
              });
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isSearching ? null : _findGuest,
            icon: _isSearching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_add_alt_rounded, size: 18),
            label: Text(_isSearching ? 'Searching…' : 'Find room / guest'),
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 12),
            ErrorStateView(
              title: 'No booking found',
              message: _searchError!,
              onRetry: _findGuest,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CompactDateField(
                  label: 'Booking date',
                  value: _bookingDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  onPick: (date) => setState(() {
                    _bookingDate = date;
                    _activeRecord = null;
                    _searchError = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactTimeField(
                  label: 'Booking time',
                  value: _bookingTime,
                  onPick: (time) => setState(() => _bookingTime = time),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- step 2

  Widget _reviewStep() {
    final roomNumber = _activeRecord?.roomNumber ?? 101;

    return AppPanel(
      key: const ValueKey('step-review'),
      title: 'Review & update details',
      subtitle: _activeRecord?.bookingId ?? 'New arrival',
      leadingIcon: Icons.fact_check_outlined,
      trailing: RoomNumberBadge(roomNumber: roomNumber, dense: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('room-$roomNumber'),
                  initialValue: '$roomNumber',
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Room no.'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _rentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rent (₹)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _gstController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'GST (%)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CompactDateField(
                  label: 'Checkout date',
                  value: _checkoutDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  onPick: (date) => setState(() => _checkoutDate = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _guestNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Guest name',
              errorText: _nameError,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _adultsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Adults'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _kidsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Kids'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _UploadField(
            fileName: _idProofName,
            onTap: () => setState(
              () => _idProofName = _idProofName == null
                  ? 'guest_id_proof.pdf'
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          _chargesSummary(),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.sync_rounded, size: 17),
                label: const Text('Update'),
              ),
              OutlinedButton.icon(
                onPressed: () => _goToStep(0),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Change guest'),
              ),
              FilledButton.icon(
                onPressed: () => _goToStep(2),
                icon: const Icon(Icons.check_rounded, size: 17),
                label: const Text('Confirm details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chargesSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Additional charges',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          _AmountLine(
            label: 'Room charge',
            value: Formatters.currency.format(_roomCharge),
          ),
          _AmountLine(
            label: 'Extra charges',
            value: Formatters.currency.format(_extraCharges),
          ),
          _AmountLine(
            label: 'Tax (GST)',
            value: Formatters.currency.format(_tax),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- step 3

  Widget _paymentStep() {
    return AppPanel(
      key: const ValueKey('step-payment'),
      title: 'Finalize check-in & payment',
      subtitle: _guestNameController.text.trim().isEmpty
          ? 'No guest selected'
          : _guestNameController.text.trim(),
      leadingIcon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AmountLine(
            label: 'Room charge',
            value: Formatters.currency.format(_roomCharge),
          ),
          _AmountLine(
            label: 'Extra charges',
            value: Formatters.currency.format(_extraCharges),
          ),
          _AmountLine(
            label: 'Tax (GST)',
            value: Formatters.currency.format(_tax),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          _AmountLine(
            label: 'Total amount',
            value: Formatters.currency.format(_total),
            emphasis: true,
          ),
          _AmountLine(
            label: 'Total paid',
            value: Formatters.currency.format(_total),
            emphasis: true,
          ),
          const SizedBox(height: 14),
          InlineMessage(
            message: _checkInCompleted
                ? 'Check-in completed. Registration card and folio are ready.'
                : 'Payment captured via M-Pay. Folio is ready to print.',
            tone: MessageTone.success,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _checkInCompleted || _isCompleting
                ? null
                : _completeCheckIn,
            style: FilledButton.styleFrom(
              backgroundColor: _checkInCompleted
                  ? AppColors.successDark
                  : AppColors.primary,
              disabledBackgroundColor: _checkInCompleted
                  ? AppColors.successDark
                  : AppColors.primary.withValues(alpha: 0.45),
              disabledForegroundColor: Colors.white,
            ),
            icon: Icon(
              _checkInCompleted
                  ? Icons.check_circle_rounded
                  : Icons.how_to_reg_rounded,
              size: 18,
            ),
            label: Text(
              _isCompleting
                  ? 'Completing…'
                  : _checkInCompleted
                  ? 'Checked in'
                  : 'Complete check-in',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _notify('Registration card sent to printer.'),
                  icon: const Icon(Icons.print_outlined, size: 17),
                  label: const Text(
                    'Print card',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _notify('Folio downloaded.'),
                  icon: const Icon(Icons.download_rounded, size: 17),
                  label: const Text(
                    'Folio',
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

  void _notify(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------- guest list

  Widget _guestList() {
    final records = _filteredRecords;

    return AppPanel(
      title: 'Guest list',
      subtitle: '${records.length} booked awaiting check-in',
      leadingIcon: Icons.groups_outlined,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: records.isEmpty
          ? EmptyStateView(
              icon: Icons.person_off_outlined,
              title: 'No booked rooms',
              message:
                  'No pending bookings for this date. Try another check-in date.',
              actionLabel: 'Clear search',
              compact: true,
              onAction: () {
                _searchController.clear();
                setState(() => _searchError = null);
              },
            )
          : Column(
              children: records.map((record) {
                final selected = _activeRecord?.bookingId == record.bookingId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _GuestListRow(
                    record: record,
                    selected: selected,
                    onTap: () => setState(() {
                      _applyRecord(record);
                      _currentStep = 1;
                    }),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ---------------------------------------------------------------- fragments

class _GuestListRow extends StatelessWidget {
  const _GuestListRow({
    required this.record,
    required this.selected,
    required this.onTap,
  });

  final GuestRecord record;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.07)
          : AppColors.surfaceAlt.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  RoomNumberBadge(roomNumber: record.roomNumber, dense: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          record.guestName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          record.bookingId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    Formatters.currency.format(record.rent),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  AppTag(
                    label: '${record.adults} adults',
                    color: AppColors.infoDark,
                    dense: true,
                  ),
                  if (record.kids > 0)
                    AppTag(
                      label: '${record.kids} kids',
                      color: AppColors.primaryLight,
                      dense: true,
                    ),
                  AppTag(
                    label: 'GST ${record.gstPercent.toStringAsFixed(0)}%',
                    color: AppColors.accent,
                    dense: true,
                  ),
                  AppTag(
                    label: 'In ${Formatters.relativeDay(record.checkInDate)}',
                    color: AppColors.infoDark,
                    dense: true,
                  ),
                  AppTag(
                    label: 'Out ${Formatters.relativeDay(record.checkoutDate)}',
                    color: AppColors.warningDark,
                    dense: true,
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

class _UploadField extends StatelessWidget {
  const _UploadField({required this.fileName, required this.onTap});

  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.surfaceAlt.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: hasFile ? AppColors.successDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile
                  ? Icons.check_circle_outline_rounded
                  : Icons.cloud_upload_outlined,
              size: 20,
              color: hasFile ? AppColors.successDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasFile ? 'ID proof attached' : 'Upload ID proof',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    fileName ?? 'Aadhaar, passport or driving licence',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.close_rounded : Icons.add_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
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
          Text(
            value,
            style: emphasis
                ? theme.textTheme.titleMedium
                : theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
