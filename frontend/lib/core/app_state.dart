import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String _userTier = "free";
  int _remainingCredits = 3;

  String get userTier => _userTier;
  int get remainingCredits => _remainingCredits;

  void setTier(String tier) {
    if (_userTier == tier) return;
    _userTier = tier;
    if (tier == "pro") {
      _remainingCredits = 9999;
    }
    notifyListeners();
  }

  void decrementCredits() {
    if (_userTier == "pro") return;
    if (_remainingCredits > 0) {
      _remainingCredits--;
      notifyListeners();
    }
  }

  void resetCredits(int count) {
    _remainingCredits = count;
    notifyListeners();
  }
}

// Global state instance
final AppState appState = AppState();
