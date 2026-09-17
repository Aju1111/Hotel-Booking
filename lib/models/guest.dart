class GuestRecord {
  const GuestRecord({
    required this.bookingId,
    required this.guestName,
    required this.roomNumber,
    required this.rent,
    required this.gstPercent,
    required this.adults,
    required this.kids,
    required this.checkInDate,
    required this.checkoutDate,
    required this.idProof,
    this.isSeniorCitizen = false,
  });

  final String bookingId;
  final String guestName;
  final int roomNumber;
  final double rent;
  final double gstPercent;
  final int adults;
  final int kids;
  final DateTime checkInDate;
  final DateTime checkoutDate;
  final String idProof;
  final bool isSeniorCitizen;
}

class CheckoutRoom {
  const CheckoutRoom({
    required this.roomNumber,
    required this.checkIn,
    required this.checkOut,
    required this.ratePerNight,
    required this.charges,
    this.selectedForCheckout = false,
  });

  final int roomNumber;
  final DateTime checkIn;
  final DateTime checkOut;
  final double ratePerNight;
  final List<RoomCharge> charges;
  final bool selectedForCheckout;

  int get nights => checkOut.difference(checkIn).inDays;

  double get roomTotal => ratePerNight * nights;

  double get chargesTotal =>
      charges.fold(0, (sum, charge) => sum + charge.amount);

  double get total => roomTotal + chargesTotal;

  CheckoutRoom copyWith({bool? selectedForCheckout}) => CheckoutRoom(
        roomNumber: roomNumber,
        checkIn: checkIn,
        checkOut: checkOut,
        ratePerNight: ratePerNight,
        charges: charges,
        selectedForCheckout: selectedForCheckout ?? this.selectedForCheckout,
      );
}

class RoomCharge {
  const RoomCharge({
    required this.description,
    required this.date,
    required this.amount,
  });

  final String description;
  final DateTime date;
  final double amount;
}
