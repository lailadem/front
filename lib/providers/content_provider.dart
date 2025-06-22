import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/api_service.dart';

class ContentProvider extends ChangeNotifier {
  List<Content> _contents = [];
  bool _isLoading = false;
  String? _error;

  List<Content> get contents => _contents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUserContent({String? category, String? type}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result =
          await ApiService().getUserContent(category: category, type: type);
      print('ContentProvider result: $result'); // Debug print

      if (result['success']) {
        _contents = List<Content>.from(result['contents']);
        _error = null;
        print('Loaded ${_contents.length} contents'); // Debug print
      } else {
        _error = result['message'];
        _contents = [];
        print('Error loading content: $_error'); // Debug print
      }
    } catch (e) {
      _error = 'Unexpected error: $e';
      _contents = [];
      print('Exception in fetchUserContent: $e'); // Debug print
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clear() async {
    _contents = [];
    _error = null;
    notifyListeners();
  }
}
