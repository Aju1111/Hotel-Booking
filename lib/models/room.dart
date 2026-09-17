enum RoomStatus { available, occupied, dirty, maintenance, blocked }

class HotelRoom {
  const HotelRoom({
    required this.code,
    required this.roomNumber,
    required this.roomType,
    required this.pricePerNight,
    required this.maxGuests,
    this.floor = 1,
    this.status = RoomStatus.available,
    this.imageAsset,
  });

  final String code;
  final int roomNumber;
  final String roomType;
  final double pricePerNight;
  final int maxGuests;
  final int floor;
  final RoomStatus status;
  final String? imageAsset;

  bool get isAvailable => status == RoomStatus.available;

  HotelRoom copyWith({RoomStatus? status}) => HotelRoom(
    code: code,
    roomNumber: roomNumber,
    roomType: roomType,
    pricePerNight: pricePerNight,
    maxGuests: maxGuests,
    floor: floor,
    status: status ?? this.status,
    imageAsset: imageAsset,
  );
}

class MaintenanceTicket {
  const MaintenanceTicket({
    required this.issue,
    required this.technician,
    required this.eta,
  });

  final String issue;
  final String technician;
  final String eta;
}
