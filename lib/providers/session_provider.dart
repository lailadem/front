import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/api_service.dart';

class SessionProvider extends ChangeNotifier {
  List<Session> _upcomingSessions = [];
  List<Session> _pastSessions = [];
  bool _isLoading = false;
  String? _error;

  List<Session> get upcomingSessions => _upcomingSessions;
  List<Session> get pastSessions => _pastSessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void addUpcomingSession(Session session) {
    _upcomingSessions = [..._upcomingSessions, session];
    _upcomingSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    notifyListeners();
  }

  Future<void> fetchClientSessions() async {
    _isLoading = true;
    notifyListeners();
    final result = await ApiService().getClientSessions();
    if (result['success']) {
      _upcomingSessions = List<Session>.from(result['upcoming_sessions']);
      _pastSessions = List<Session>.from(result['past_sessions']);
      _error = null;
    } else {
      _error = result['message'];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> cancelSession(int sessionId) async {
    _isLoading = true;
    notifyListeners();
    final result = await ApiService().cancelSession(sessionId);
    _isLoading = false;
    notifyListeners();
    if (result['success']) {
      await fetchClientSessions();
      return true;
    } else {
      _error = result['message'];
      return false;
    }
  }

  Future<bool> deleteSession(int sessionId) async {
    _isLoading = true;
    notifyListeners();
    final result = await ApiService().deleteSession(sessionId);
    _isLoading = false;
    notifyListeners();
    if (result['success']) {
      await fetchClientSessions();
      return true;
    } else {
      _error = result['message'];
      return false;
    }
  }

  Future<void> clear() async {
    _upcomingSessions = [];
    _pastSessions = [];
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> bookSession({
    required int professionalId,
    required String scheduledAt,
    required String sessionType,
    required bool isAnonymous,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService().bookSession(
      professionalId: professionalId,
      scheduledAt: scheduledAt,
      sessionType: sessionType,
      isAnonymous: isAnonymous,
    );

    if (result['success']) {
      // Refresh the sessions list to include the newly booked one
      await fetchClientSessions();
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> fetchProfessionalSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch both upcoming and past sessions for the professional
      final upcomingResult =
          await ApiService().getProfessionalUpcomingSessions();
      final pastResult = await ApiService().getProfessionalPastSessions();

      if (upcomingResult['success']) {
        _upcomingSessions = List<Session>.from(upcomingResult['data'] ?? []);
      } else {
        _error = upcomingResult['message'];
      }

      if (pastResult['success']) {
        _pastSessions = List<Session>.from(pastResult['data'] ?? []);
      } else {
        // Append error messages if both fail
        final pastError =
            pastResult['message'] ?? 'Failed to load past sessions';
        _error = _error == null ? pastError : '$_error\n$pastError';
      }
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> professionalCancelSession(int sessionId) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService().professionalCancelSession(sessionId);

    if (result['success']) {
      await fetchProfessionalSessions(); // Refresh the session list
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }
}
