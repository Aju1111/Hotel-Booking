import 'package:hotel_booking/models/booking.dart';
import 'package:hotel_booking/models/guest.dart';
import 'package:hotel_booking/models/room.dart';

abstract final class SampleData {
  static HotelRoom _room({
    required int number,
    required RoomStatus status,
  }) {
    final floor = number ~/ 100;
    final (type, price, guests) = switch (floor) {
      1 => ('Deluxe Room', 3500.0, 2),
      2 => ('Executive Suite', 5800.0, 3),
      _ => ('Family Room', 4200.0, 4),
    };

    return HotelRoom(
      code: 'R$number',
      roomNumber: number,
      roomType: type,
      pricePerNight: price,
      maxGuests: guests,
      floor: floor,
      status: status,
      imageAsset: 'assets/images/rooms/r$number.jpg',
    );
  }

  /// Coding-test inventory (R101–R301).
  static final rooms = <HotelRoom>[
    _room(number: 101, status: RoomStatus.occupied),
    _room(number: 102, status: RoomStatus.available),
    _room(number: 201, status: RoomStatus.available),
    _room(number: 202, status: RoomStatus.dirty),
    _room(number: 301, status: RoomStatus.maintenance),
  ];

  static const maintenanceTickets = <int, MaintenanceTicket>{
    301: MaintenanceTicket(
      issue: 'AC not cooling — compressor check',
      technician: 'House Engineering',
      eta: 'Today, 6:00 PM',
    ),
  };

  static MaintenanceTicket ticketFor(int roomNumber) =>
      maintenanceTickets[roomNumber] ??
      const MaintenanceTicket(
        issue: 'General repair',
        technician: 'House Engineering',
        eta: 'Today',
      );

  static final existingBookings = <ExistingBooking>[
    ExistingBooking(
      roomCode: 'R101',
      checkIn: DateTime(2026, 4, 2),
      checkOut: DateTime(2026, 4, 4),
      guestName: 'Mathew Hyden',
    ),
    ExistingBooking(
      roomCode: 'R201',
      checkIn: DateTime(2026, 4, 10),
      checkOut: DateTime(2026, 4, 12),
      guestName: 'Sarah Thompson',
    ),
    ExistingBooking(
      roomCode: 'R301',
      checkIn: DateTime(2026, 4, 4),
      checkOut: DateTime(2026, 4, 6),
      guestName: 'James Smith',
    ),
    ExistingBooking(
      roomCode: 'R102',
      checkIn: DateTime(2026, 4, 5),
      checkOut: DateTime(2026, 4, 7),
      guestName: 'Emily Davis',
    ),
    ExistingBooking(
      roomCode: 'R202',
      checkIn: DateTime(2026, 4, 6),
      checkOut: DateTime(2026, 4, 8),
      guestName: 'Michael Brown',
    ),
  ];

  static bool roomExists(int roomNumber) =>
      rooms.any((room) => room.roomNumber == roomNumber);

  static final guestRecords = <GuestRecord>[
    GuestRecord(
      bookingId: 'BK-1021',
      guestName: 'Mathew Hyden',
      roomNumber: 101,
      rent: 3500,
      gstPercent: 12,
      adults: 2,
      kids: 0,
      checkInDate: DateTime(2026, 4, 2),
      checkoutDate: DateTime(2026, 4, 4),
      idProof: 'mathewhyden_aadhar.pdf',
    ),
    GuestRecord(
      bookingId: 'BK-1022',
      guestName: 'Sarah Thompson',
      roomNumber: 201,
      rent: 5800,
      gstPercent: 12,
      adults: 1,
      kids: 1,
      checkInDate: DateTime(2026, 4, 10),
      checkoutDate: DateTime(2026, 4, 12),
      idProof: 'sarah_thompson_passport.pdf',
    ),
    GuestRecord(
      bookingId: 'BK-1023',
      guestName: 'James Smith',
      roomNumber: 301,
      rent: 4200,
      gstPercent: 12,
      adults: 2,
      kids: 2,
      checkInDate: DateTime(2026, 4, 4),
      checkoutDate: DateTime(2026, 4, 6),
      idProof: 'james_smith_dl.pdf',
    ),
    GuestRecord(
      bookingId: 'BK-1024',
      guestName: 'Emily Davis',
      roomNumber: 102,
      rent: 3500,
      gstPercent: 12,
      adults: 2,
      kids: 0,
      checkInDate: DateTime(2026, 4, 5),
      checkoutDate: DateTime(2026, 4, 7),
      idProof: 'emily_davis_aadhar.pdf',
    ),
    GuestRecord(
      bookingId: 'BK-1025',
      guestName: 'Michael Brown',
      roomNumber: 202,
      rent: 3500,
      gstPercent: 12,
      adults: 1,
      kids: 0,
      checkInDate: DateTime(2026, 4, 6),
      checkoutDate: DateTime(2026, 4, 8),
      idProof: 'michael_brown_voter.pdf',
    ),
  ];

  static List<CheckoutRoom> checkoutRoomsForGuest(String guestName) {
    return List<CheckoutRoom>.from(_folios[guestName] ?? const []);
  }

  static final _folios = <String, List<CheckoutRoom>>{
    'Mathew Hyden': [
      CheckoutRoom(
        roomNumber: 101,
        checkIn: DateTime(2026, 4, 2),
        checkOut: DateTime(2026, 4, 4),
        ratePerNight: 1200,
        selectedForCheckout: true,
        charges: [
          RoomCharge(
            description: 'Mini-bar (Water x2)',
            date: DateTime(2026, 4, 3),
            amount: 200,
          ),
          RoomCharge(
            description: 'Room Service',
            date: DateTime(2026, 4, 3),
            amount: 450,
          ),
          RoomCharge(
            description: 'Restaurant Bill (Room 101)',
            date: DateTime(2026, 4, 3),
            amount: 1500,
          ),
        ],
      ),
    ],
    'Sarah Thompson': [
      CheckoutRoom(
        roomNumber: 201,
        checkIn: DateTime(2026, 4, 10),
        checkOut: DateTime(2026, 4, 12),
        ratePerNight: 5800,
        selectedForCheckout: true,
        charges: [
          RoomCharge(
            description: 'Laundry',
            date: DateTime(2026, 4, 11),
            amount: 250,
          ),
        ],
      ),
    ],
    'James Smith': [
      CheckoutRoom(
        roomNumber: 301,
        checkIn: DateTime(2026, 4, 4),
        checkOut: DateTime(2026, 4, 6),
        ratePerNight: 4200,
        selectedForCheckout: true,
        charges: const [],
      ),
    ],
    'Emily Davis': [
      CheckoutRoom(
        roomNumber: 102,
        checkIn: DateTime(2026, 4, 5),
        checkOut: DateTime(2026, 4, 7),
        ratePerNight: 3500,
        selectedForCheckout: true,
        charges: const [],
      ),
    ],
  };

  static const dashboardGuests = [
    'Mathew Hyden',
    'Sarah Thompson',
    'James Smith',
    'Emily Davis',
  ];
}
