class StaffUser {
  const StaffUser({
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    required this.employeeId,
    required this.email,
    required this.phone,
    required this.shift,
    required this.shiftLabel,
  });

  final String username;
  final String password;
  final String name;
  final String role;
  final String employeeId;
  final String email;
  final String phone;
  final String shift;
  final String shiftLabel;

  String get firstName => name.split(' ').first;

  /// Single letter shown in the header avatar circle.
  String get avatarLetter {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  /// Two-letter initials for the profile page.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    final trimmed = name.trim();
    if (trimmed.length >= 2) {
      return trimmed.substring(0, 2).toUpperCase();
    }
    return avatarLetter;
  }
}
