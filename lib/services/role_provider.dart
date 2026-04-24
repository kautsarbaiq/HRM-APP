import 'package:flutter/material.dart';

class RoleProvider extends ChangeNotifier {
  bool _isAdmin = false;

  bool get isAdmin => _isAdmin;
  bool get isStaff => !_isAdmin;

  void toggleRole() {
    _isAdmin = !_isAdmin;
    notifyListeners();
  }

  void setAdmin() {
    _isAdmin = true;
    notifyListeners();
  }

  void setStaff() {
    _isAdmin = false;
    notifyListeners();
  }
}
