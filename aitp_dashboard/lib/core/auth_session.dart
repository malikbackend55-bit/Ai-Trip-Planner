import 'package:flutter/foundation.dart';

class AuthSession extends ChangeNotifier {
  bool _sessionExpired = false;

  bool get sessionExpired => _sessionExpired;

  void markSessionExpired() {
    if (_sessionExpired) {
      return;
    }

    _sessionExpired = true;
    notifyListeners();
  }

  void markAuthenticated() {
    if (!_sessionExpired) {
      return;
    }

    _sessionExpired = false;
    notifyListeners();
  }

  void markLoggedOut() {
    if (!_sessionExpired) {
      _sessionExpired = true;
      notifyListeners();
      return;
    }

    notifyListeners();
  }
}

final authSession = AuthSession();
