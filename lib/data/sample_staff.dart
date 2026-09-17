import 'package:hotel_booking/models/staff_user.dart';

abstract final class SampleStaff {
  static const accounts = <StaffUser>[
    StaffUser(
      username: 'admin',
      password: 'admin',
      name: 'Admin User',
      role: 'Front Desk Manager',
      employeeId: 'RT-FD-014',
      email: 'admin@raintech.hotel',
      phone: '+91 98765 44110',
      shift: '2:00 PM – 10:00 PM',
      shiftLabel: 'Evening shift',
    ),
    StaffUser(
      username: 'sarah',
      password: 'sarah',
      name: 'Sarah Thompson',
      role: 'Front Desk Executive',
      employeeId: 'RT-FD-022',
      email: 'sarah@raintech.hotel',
      phone: '+91 98765 44118',
      shift: '8:00 AM – 4:00 PM',
      shiftLabel: 'Morning shift',
    ),
    StaffUser(
      username: 'john',
      password: 'john',
      name: 'John Mathew',
      role: 'Night Shift Supervisor',
      employeeId: 'RT-FD-031',
      email: 'john@raintech.hotel',
      phone: '+91 98765 44125',
      shift: '10:00 PM – 6:00 AM',
      shiftLabel: 'Night shift',
    ),
  ];
}
