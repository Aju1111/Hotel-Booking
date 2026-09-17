class ExistingBooking {
  const ExistingBooking({
    required this.roomCode,
    required this.checkIn,
    required this.checkOut,
    required this.guestName,
  });

  final String roomCode;
  final DateTime checkIn;
  final DateTime checkOut;
  final String guestName;

  bool overlaps(DateTime checkIn, DateTime checkOut) {
    final start = _dateOnly(checkIn);
    final end = _dateOnly(checkOut);
    final bookingStart = _dateOnly(this.checkIn);
    final bookingEnd = _dateOnly(this.checkOut);
    return start.isBefore(bookingEnd) && end.isAfter(bookingStart);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class BookingSummary {
  const BookingSummary({
    required this.nights,
    required this.totalPrice,
    required this.isValid,
    this.errorMessage,
  });

  final int nights;
  final double totalPrice;
  final bool isValid;
  final String? errorMessage;
}
