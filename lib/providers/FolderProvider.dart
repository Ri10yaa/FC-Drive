import 'package:flutter/material.dart';

class FolderProvider with ChangeNotifier {
  List<String> _currentPath = [];

  List<String> get currentPath => List.unmodifiable(_currentPath);

  // Navigate to a folder: Add folder name to the current path
  void navigateToFolder(String folderName) {
    _currentPath.add(folderName);
    notifyListeners();
  }

  // Navigate back: Remove the last folder from the current path
  void navigateBack() {
    if (_currentPath.isNotEmpty) {
      _currentPath.removeLast();
      notifyListeners();
    }
  }

  // Reset the path to root
  void resetPath() {
    _currentPath.clear();
    notifyListeners();
  }

  // Set a specific folder path (useful if navigating to a deep folder directly)
  void setPath(List<String> newPath) {
    _currentPath = newPath;
    notifyListeners();
  }
}
