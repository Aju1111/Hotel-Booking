import 'package:hotel_booking/models/booking.dart';
import 'package:hotel_booking/models/room.dart';

class BookingCalculator {
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static BookingSummary calculate({
    required DateTime? checkIn,
    required DateTime? checkOut,
    required HotelRoom? room,
    required List<ExistingBooking> existingBookings,
    DateTime? today,
  }) {
    final now = dateOnly(today ?? DateTime.now());

    if (checkIn == null || checkOut == null) {
      return const BookingSummary(
        nights: 0,
        totalPrice: 0,
        isValid: false,
        errorMessage: 'Please select check-in and check-out dates.',
      );
    }

    final start = dateOnly(checkIn);
    final end = dateOnly(checkOut);

    if (start.isBefore(now)) {
      return const BookingSummary(
        nights: 0,
        totalPrice: 0,
        isValid: false,
        errorMessage: 'Check-in cannot be in the past.',
      );
    }

    if (!end.isAfter(start)) {
      return const BookingSummary(
        nights: 0,
        totalPrice: 0,
        isValid: false,
        errorMessage: 'Check-out must be after check-in.',
      );
    }

    if (room == null) {
      return const BookingSummary(
        nights: 0,
        totalPrice: 0,
        isValid: false,
        errorMessage: 'Please select a room to continue.',
      );
    }

    final nights = end.difference(start).inDays;
    if (nights <= 0) {
      return const BookingSummary(
        nights: 0,
        totalPrice: 0,
        isValid: false,
        errorMessage: 'Stay must be at least one night.',
      );
    }

    final isBooked = existingBookings.any(
      (booking) =>
          booking.roomCode == room.code && booking.overlaps(start, end),
    );

    if (isBooked) {
      return BookingSummary(
        nights: nights,
        totalPrice: room.pricePerNight * nights,
        isValid: false,
        errorMessage:
            '${room.code} is already booked for the selected dates.',
      );
    }

    return BookingSummary(
      nights: nights,
      totalPrice: room.pricePerNight * nights,
      isValid: true,
    );
  }

  static bool isRoomAvailableForDates({
    required HotelRoom room,
    required DateTime checkIn,
    required DateTime checkOut,
    required List<ExistingBooking> existingBookings,
  }) {
    return !existingBookings.any(
      (booking) =>
          booking.roomCode == room.code &&
          booking.overlaps(checkIn, checkOut),
    );
  }
}
