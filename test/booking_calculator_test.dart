import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking/models/booking.dart';
import 'package:hotel_booking/models/room.dart';
import 'package:hotel_booking/utils/booking_calculator.dart';

void main() {
  const room = HotelRoom(
    code: 'R102',
    roomNumber: 102,
    roomType: 'Deluxe Room',
    pricePerNight: 3500,
    maxGuests: 2,
  );

  final existingBookings = [
    ExistingBooking(
      roomCode: 'R101',
      checkIn: DateTime(2026, 4, 2),
      checkOut: DateTime(2026, 4, 4),
      guestName: 'Mathew Hyden',
    ),
  ];

  final today = DateTime(2026, 4, 1);

  group('BookingCalculator', () {
    test('calculates nights and total price correctly', () {
      final summary = BookingCalculator.calculate(
        checkIn: DateTime(2026, 4, 5),
        checkOut: DateTime(2026, 4, 8),
        room: room,
        existingBookings: existingBookings,
        today: today,
      );

      expect(summary.isValid, isTrue);
      expect(summary.nights, 3);
      expect(summary.totalPrice, 10500);
    });

    test('rejects check-out on or before check-in', () {
      final summary = BookingCalculator.calculate(
        checkIn: DateTime(2026, 4, 5),
        checkOut: DateTime(2026, 4, 5),
        room: room,
        existingBookings: existingBookings,
        today: today,
      );

      expect(summary.isValid, isFalse);
      expect(summary.errorMessage, contains('after check-in'));
    });

    test('rejects check-in in the past', () {
      final summary = BookingCalculator.calculate(
        checkIn: DateTime(2026, 3, 30),
        checkOut: DateTime(2026, 4, 2),
        room: room,
        existingBookings: existingBookings,
        today: today,
      );

      expect(summary.isValid, isFalse);
      expect(summary.errorMessage, contains('past'));
    });

    test('rejects overlapping existing bookings', () {
      final summary = BookingCalculator.calculate(
        checkIn: DateTime(2026, 4, 3),
        checkOut: DateTime(2026, 4, 6),
        room: const HotelRoom(
          code: 'R101',
          roomNumber: 101,
          roomType: 'Deluxe Room',
          pricePerNight: 3500,
          maxGuests: 2,
        ),
        existingBookings: existingBookings,
        today: today,
      );

      expect(summary.isValid, isFalse);
      expect(summary.errorMessage, contains('already booked'));
    });

    test('requires room selection', () {
      final summary = BookingCalculator.calculate(
        checkIn: DateTime(2026, 4, 5),
        checkOut: DateTime(2026, 4, 8),
        room: null,
        existingBookings: existingBookings,
        today: today,
      );

      expect(summary.isValid, isFalse);
      expect(summary.errorMessage, contains('select a room'));
    });
  });
}
