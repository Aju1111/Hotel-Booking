import 'package:hotel_booking/data/sample_data.dart';
import 'package:hotel_booking/models/booking.dart';
import 'package:hotel_booking/models/guest.dart';
import 'package:hotel_booking/models/room.dart';
import 'package:hotel_booking/utils/booking_calculator.dart';
import 'package:hotel_booking/utils/formatters.dart';

/// In-memory front-desk state for this app session.
/// Lifecycle: booked → checked in → checked out.
class FrontDeskSession {
  FrontDeskSession._();

  static final FrontDeskSession instance = FrontDeskSession._();

  final Set<int> _checkedOutRooms = {};
  final Set<String> _checkedOutGuests = {};
  final Set<int> _bookedRooms = {};
  final Set<String> _checkedInBookingIds = {};
  final List<ExistingBooking> _sessionBookings = [];
  final List<GuestRecord> _sessionPendingCheckIns = [];
  final Map<int, RoomStatus> _statusOverrides = {};
  final Map<String, List<CheckoutRoom>> _checkedInFolios = {};
  int _sessionBookingCounter = 0;

  void reset() {
    _checkedOutRooms.clear();
    _checkedOutGuests.clear();
    _bookedRooms.clear();
    _checkedInBookingIds.clear();
    _sessionBookings.clear();
    _sessionPendingCheckIns.clear();
    _statusOverrides.clear();
    _checkedInFolios.clear();
    _sessionBookingCounter = 0;
  }

  List<ExistingBooking> get sessionBookings =>
      List.unmodifiable(_sessionBookings);

  List<ExistingBooking> get allBookings => [
    ...SampleData.existingBookings,
    ..._sessionBookings,
  ];

  bool isBookingCheckedIn(String bookingId) =>
      _checkedInBookingIds.contains(bookingId);

  bool isGuestCheckedOut(String guestName) =>
      _checkedOutGuests.contains(guestName);

  /// Bookings waiting for front-desk check-in.
  List<GuestRecord> pendingCheckInRecords({DateTime? checkInDate}) {
    final target = checkInDate == null
        ? null
        : BookingCalculator.dateOnly(checkInDate);

    final sample = SampleData.guestRecords.where(
      (record) => _isPendingCheckIn(record, target, requireSampleBooking: true),
    );
    final session = _sessionPendingCheckIns.where(
      (record) => _isPendingCheckIn(record, target, requireSampleBooking: false),
    );

    return [...sample, ...session];
  }

  bool _isPendingCheckIn(
    GuestRecord record,
    DateTime? target, {
    required bool requireSampleBooking,
  }) {
    if (isBookingCheckedIn(record.bookingId)) return false;
    if (isGuestCheckedOut(record.guestName)) return false;
    if (!SampleData.roomExists(record.roomNumber)) return false;
    if (requireSampleBooking && !_hasActiveBooking(record)) return false;
    if (target == null) return true;
    return BookingCalculator.dateOnly(record.checkInDate) == target;
  }

  bool _hasActiveBooking(GuestRecord record) {
    final roomCode = 'R${record.roomNumber}';
    final checkIn = BookingCalculator.dateOnly(record.checkInDate);

    return allBookings.any(
      (booking) =>
          booking.roomCode == roomCode &&
          booking.guestName == record.guestName &&
          BookingCalculator.dateOnly(booking.checkIn) == checkIn,
    );
  }

  bool isGuestCheckedIn(String guestName) =>
      remainingRoomsFor(guestName).isNotEmpty;

  void bookRoom({
    required HotelRoom room,
    required DateTime checkIn,
    required DateTime checkOut,
    String guestName = 'Walk-in guest',
  }) {
    _bookedRooms.add(room.roomNumber);
    _checkedOutRooms.remove(room.roomNumber);
    _statusOverrides[room.roomNumber] = RoomStatus.occupied;

    final bookingId =
        'BK-${room.code}-${++_sessionBookingCounter}${checkIn.millisecondsSinceEpoch % 10000}';

    _sessionBookings.add(
      ExistingBooking(
        roomCode: room.code,
        checkIn: checkIn,
        checkOut: checkOut,
        guestName: guestName,
      ),
    );
    _sessionPendingCheckIns.add(
      GuestRecord(
        bookingId: bookingId,
        guestName: guestName,
        roomNumber: room.roomNumber,
        rent: room.pricePerNight,
        gstPercent: 12,
        adults: room.maxGuests.clamp(1, 4),
        kids: 0,
        checkInDate: BookingCalculator.dateOnly(checkIn),
        checkoutDate: BookingCalculator.dateOnly(checkOut),
        idProof: '',
      ),
    );
  }

  void completeCheckIn({
    required GuestRecord record,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) {
    if (isBookingCheckedIn(record.bookingId)) return;

    _checkedInBookingIds.add(record.bookingId);
    _checkedOutGuests.remove(record.guestName);
    _bookedRooms.add(record.roomNumber);
    _checkedOutRooms.remove(record.roomNumber);
    _statusOverrides[record.roomNumber] = RoomStatus.occupied;

    final folioRoom = CheckoutRoom(
      roomNumber: record.roomNumber,
      checkIn: BookingCalculator.dateOnly(checkInDate),
      checkOut: BookingCalculator.dateOnly(checkOutDate),
      ratePerNight: record.rent,
      selectedForCheckout: true,
      charges: const [],
    );

    final folio = _checkedInFolios.putIfAbsent(record.guestName, () => []);
    if (!folio.any((room) => room.roomNumber == record.roomNumber)) {
      folio.add(folioRoom);
    }
  }

  void completeCheckout({
    required String guestName,
    required Iterable<int> roomNumbers,
  }) {
    _checkedOutRooms.addAll(roomNumbers);
    _bookedRooms.removeAll(roomNumbers);
    for (final roomNumber in roomNumbers) {
      _statusOverrides[roomNumber] = RoomStatus.dirty;
    }
    if (remainingRoomsFor(guestName).isEmpty) {
      _checkedOutGuests.add(guestName);
    }
  }

  void setRoomStatus(int roomNumber, RoomStatus status) {
    _statusOverrides[roomNumber] = status;
    if (status == RoomStatus.occupied) {
      _bookedRooms.add(roomNumber);
    } else {
      _bookedRooms.remove(roomNumber);
    }
    if (status != RoomStatus.dirty) {
      _checkedOutRooms.remove(roomNumber);
    }
  }

  RoomStatus liveStatus(HotelRoom room) {
    if (_statusOverrides.containsKey(room.roomNumber)) {
      return _statusOverrides[room.roomNumber]!;
    }
    if (_bookedRooms.contains(room.roomNumber)) return RoomStatus.occupied;
    if (_checkedOutRooms.contains(room.roomNumber)) return RoomStatus.dirty;
    return room.status;
  }

  HotelRoom withLiveStatus(HotelRoom room) =>
      room.copyWith(status: liveStatus(room));

  List<HotelRoom> get rooms =>
      SampleData.rooms.map(withLiveStatus).toList();

  List<CheckoutRoom> remainingRoomsFor(String guestName) {
    if (!_checkedInFolios.containsKey(guestName)) return [];

    return _checkedInFolios[guestName]!
        .where((room) => !_checkedOutRooms.contains(room.roomNumber))
        .toList();
  }

  List<CheckoutRoom> checkedInRoomsForDate(DateTime checkInDate) {
    final target = BookingCalculator.dateOnly(checkInDate);
    final rooms = <CheckoutRoom>[];

    for (final guest in departingGuests) {
      for (final room in remainingRoomsFor(guest)) {
        if (BookingCalculator.dateOnly(room.checkIn) == target) {
          rooms.add(room);
        }
      }
    }

    return rooms;
  }

  List<String> get departingGuests {
    return _checkedInFolios.keys
        .where((guest) => remainingRoomsFor(guest).isNotEmpty)
        .toList()
      ..sort();
  }

  List<String> departingGuestsForCheckInDate(DateTime checkInDate) {
    final target = BookingCalculator.dateOnly(checkInDate);
    return departingGuests.where((guest) {
      return remainingRoomsFor(guest).any(
        (room) => BookingCalculator.dateOnly(room.checkIn) == target,
      );
    }).toList();
  }

  String? guestForRoom(int roomNumber) {
    for (final guest in departingGuests) {
      if (remainingRoomsFor(guest).any((room) => room.roomNumber == roomNumber)) {
        return guest;
      }
    }
    return null;
  }

  /// Seeds checked-in folios for widget tests.
  void seedCheckedInDemoGuests() {
    final checkIn = Formatters.today;
    final checkOut = checkIn.add(const Duration(days: 2));

    for (final record in SampleData.guestRecords) {
      if (record.bookingId == 'BK-1021' || record.bookingId == 'BK-1022') {
        completeCheckIn(
          record: record,
          checkInDate: checkIn,
          checkOutDate: checkOut,
        );
      }
    }
  }
}
