import 'package:flutter/material.dart';
import '../models/user.dart'; // Import the User model

class UserProvider with ChangeNotifier {
  CUser? _user;

  CUser? get user => _user;

  void setUser(CUser user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
