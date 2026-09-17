import 'package:flutter/foundation.dart';
import 'package:hotel_booking/data/sample_staff.dart';
import 'package:hotel_booking/models/staff_user.dart';

/// Tracks who is signed in for this app session.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  StaffUser? _currentUser;

  bool get isLoggedIn => _currentUser != null;

  StaffUser? get currentUser => _currentUser;

  String get avatarLetter => _currentUser?.avatarLetter ?? '?';

  bool login(String username, String password) {
    final normalizedUsername = username.trim().toLowerCase();
    final match = SampleStaff.accounts.where(
      (user) =>
          user.username == normalizedUsername && user.password == password,
    );

    if (match.isEmpty) return false;

    _currentUser = match.first;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
