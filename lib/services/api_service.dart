import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/session.dart';
import '../models/content.dart';
import '../models/chat_message.dart';

// Generic API Response Wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  bool get success => error == null;

  ApiResponse({this.data, this.error});
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // --- Private Helper Methods ---
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SharedPrefsKeys.token);
  }

  Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final token = await _getToken();
    return {
      if (!isMultipart) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  Future<Map<String, dynamic>> _handleRequest(
      Future<http.Response> requestFuture) async {
    http.Response response;
    try {
      response = await requestFuture;
    } catch (e) {
      throw Exception('Network request failed: $e');
    }

    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data is Map<String, dynamic> ? data : {'data': data};
    } else {
      throw Exception(data['message'] ?? 'An unknown error occurred');
    }
  }

  Future<Map<String, dynamic>> _executeApiCall(
    Future<Map<String, dynamic>> apiCall, {
    String? successKey,
    Function? dataMapper,
  }) async {
    try {
      final result = await apiCall;
      dynamic data = result;

      // If a specific key holds the main data, extract it.
      if (successKey != null && result.containsKey(successKey)) {
        data = result[successKey];
      }

      // If a mapper function is provided, transform the data.
      if (dataMapper != null) {
        // Handle cases where data might be a list or a single object.
        if (data is List) {
          data = data.map((item) => dataMapper(item)).toList();
        } else {
          data = dataMapper(data);
        }
      }

      return {'success': true, successKey ?? 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Generic Request Methods ---
  Future<Map<String, dynamic>> _get(String endpoint,
      {Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint')
        .replace(queryParameters: query);
    return await _handleRequest(http.get(uri, headers: await _getHeaders()));
  }

  Future<Map<String, dynamic>> _post(String endpoint, {Object? body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    return await _handleRequest(
        http.post(uri, headers: await _getHeaders(), body: json.encode(body)));
  }

  Future<Map<String, dynamic>> _put(String endpoint, {Object? body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    return await _handleRequest(
        http.put(uri, headers: await _getHeaders(), body: json.encode(body)));
  }

  Future<Map<String, dynamic>> _patch(String endpoint, {Object? body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    return await _handleRequest(
        http.patch(uri, headers: await _getHeaders(), body: json.encode(body)));
  }

  Future<Map<String, dynamic>> _delete(String endpoint) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    return await _handleRequest(http.delete(uri, headers: await _getHeaders()));
  }

  // --- Public API Methods ---

  // Auth
  Future<Map<String, dynamic>> register(
      {required String name,
      required String email,
      required String password,
      required String role}) async {
    return _executeApiCall(_post(ApiEndpoints.register, body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role
    }));
  }

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    try {
      final data = await _post(ApiEndpoints.login,
          body: {'email': email, 'password': password});
      if (data.containsKey('access_token') && data['user']?['role'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(SharedPrefsKeys.token, data['access_token']);
        await prefs.setString(
            SharedPrefsKeys.userData, json.encode(data['user']));
        await prefs.setBool(SharedPrefsKeys.isLoggedIn, true);
        await prefs.setString(SharedPrefsKeys.userRole, data['user']['role']);
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        throw Exception("Invalid login response from server.");
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    final result = await _executeApiCall(_post(ApiEndpoints.logout));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    return result;
  }

  // User Management
  Future<Map<String, dynamic>> getUserProfile() async {
    return _executeApiCall(_get(ApiEndpoints.userProfile),
        dataMapper: (d) => User.fromJson(d));
  }

  Future<Map<String, dynamic>> updateAccount(
      {required String name, required String email}) async {
    return _executeApiCall(
        _put(ApiEndpoints.updateAccount, body: {'name': name, 'email': email}));
  }

  Future<Map<String, dynamic>> updatePassword(
      {required String currentPassword,
      required String newPassword,
      required String newPasswordConfirmation}) async {
    return _executeApiCall(_put(ApiEndpoints.updatePassword, body: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation
    }));
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    return _executeApiCall(_delete(ApiEndpoints.deleteAccount));
  }

  // Session Management
  Future<Map<String, dynamic>> bookSession(
      {required int professionalId,
      required String scheduledAt,
      required String sessionType,
      required bool isAnonymous}) async {
    final body = {
      'professional_id': professionalId,
      'scheduled_at': scheduledAt,
      'communication_type': sessionType,
      'is_anonymous': isAnonymous
    };
    return _executeApiCall(_post(ApiEndpoints.bookSession, body: body),
        successKey: 'session', dataMapper: (d) => Session.fromJson(d));
  }

  Future<Map<String, dynamic>> getClientSessions() async {
    try {
      final data = await _get(ApiEndpoints.clientSessions);
      final allSessions = (data['my_sessions'] as List)
          .map((s) => Session.fromJson(s))
          .toList();
      final now = DateTime.now();
      final upcoming = allSessions
          .where((s) =>
              DateTime.parse(s.scheduledAt).isAfter(now) &&
              s.status != 'cancelled' &&
              s.status != 'completed')
          .toList();
      final past = allSessions
          .where((s) =>
              DateTime.parse(s.scheduledAt).isBefore(now) ||
              s.status == 'cancelled' ||
              s.status == 'completed')
          .toList();
      return {
        'success': true,
        'upcoming_sessions': upcoming,
        'past_sessions': past
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> cancelSession(int sessionId) async {
    return _executeApiCall(
        _patch('${ApiEndpoints.clientCancelSession}/$sessionId'));
  }

  Future<Map<String, dynamic>> deleteSession(int sessionId) async {
    return _executeApiCall(
        _delete('${ApiEndpoints.clientDeleteSession}/$sessionId'));
  }

  Future<Map<String, dynamic>> joinSession(int sessionId) async {
    return _executeApiCall(
        _get('${ApiEndpoints.clientJoinSession}/$sessionId'));
  }

  Future<Map<String, dynamic>> submitFeedback(
      {required int sessionId,
      required String rating,
      required String comments}) async {
    return _executeApiCall(_post(ApiEndpoints.clientFeedback, body: {
      'session_id': sessionId,
      'rating': rating,
      'comments': comments
    }));
  }

  // Professional
  Future<Map<String, dynamic>> getProfessionalUpcomingSessions() async {
    try {
      final result = await _get(ApiEndpoints.professionalUpcomingSessions);
      if (result['data'] != null && result['data'] is List) {
        final sessionsList = (result['data'] as List)
            .map((item) => Session.fromJson(item))
            .toList();
        return {'success': true, 'data': sessionsList};
      } else {
        return {'success': true, 'data': <Session>[]};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProfessionalPastSessions() async {
    try {
      final result = await _get(ApiEndpoints.professionalPastSessions);
      if (result['data'] != null && result['data'] is List) {
        final sessionsList = (result['data'] as List)
            .map((item) => Session.fromJson(item))
            .toList();
        return {'success': true, 'data': sessionsList};
      } else {
        return {'success': true, 'data': <Session>[]};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> professionalJoinSession(int sessionId) async {
    return _executeApiCall(
        _get('${ApiEndpoints.professionalJoinSession}/$sessionId'));
  }

  Future<Map<String, dynamic>> professionalCancelSession(int sessionId) async {
    return _executeApiCall(
        _patch('${ApiEndpoints.professionalCancelSession}/$sessionId'));
  }

  Future<Map<String, dynamic>> professionalCompleteSession(
      int sessionId) async {
    return _executeApiCall(
        _patch('${ApiEndpoints.professionalCompleteSession}/$sessionId'));
  }

  Future<Map<String, dynamic>> addAvailability(
      {required String availableDate,
      required String startTime,
      required String endTime}) async {
    return _executeApiCall(_post(ApiEndpoints.professionalAvailability, body: {
      'available_date': availableDate,
      'start_time': startTime,
      'end_time': endTime
    }));
  }

  Future<Map<String, dynamic>> getProfessionalAvailabilities() async {
    return _executeApiCall(_get(ApiEndpoints.professionalAvailability));
  }

  // Content Management
  Future<Map<String, dynamic>> getProfessionalContent() async {
    try {
      final result = await _get(ApiEndpoints.professionalViewContent);
      // The actual content list is nested inside the paginated response
      if (result['contents'] != null && result['contents']['data'] is List) {
        final contentsList = (result['contents']['data'] as List)
            .map((item) => Content.fromJson(item))
            .toList();
        return {'success': true, 'contents': contentsList};
      } else {
        // Handle cases where the structure might be different or empty
        return {'success': true, 'contents': <Content>[]};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getUserContent(
      {String? category, String? type}) async {
    final query = <String, String>{};
    if (category != null) query['category'] = category;
    if (type != null) query['type'] = type;

    try {
      final result = await _get(ApiEndpoints.userContent, query: query);
      if (result['contents'] != null && result['contents']['data'] is List) {
        final contentsList = (result['contents']['data'] as List)
            .map((item) => Content.fromJson(item))
            .toList();
        return {'success': true, 'contents': contentsList};
      } else {
        return {'success': true, 'contents': <Content>[]};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getUserContentTypes() async {
    return _executeApiCall(_get(ApiEndpoints.userContentTypes),
        successKey: 'content_types');
  }

  Future<Map<String, dynamic>> updateContent(
      {required int contentId,
      String? description,
      String? type,
      int? contentTypeId}) async {
    final body = <String, dynamic>{};
    if (description != null) {
      body['description'] = description;
    }
    if (type != null) {
      body['type'] = type;
    }
    if (contentTypeId != null) {
      body['content_type_id'] = contentTypeId.toString();
    }
    return _executeApiCall(
        _put('${ApiEndpoints.professionalUpdateContent}/$contentId',
            body: body),
        successKey: 'data',
        dataMapper: (d) => Content.fromJson(d));
  }

  Future<Map<String, dynamic>> deleteContent(int contentId) async {
    return _executeApiCall(
        _delete('${ApiEndpoints.professionalDeleteContent}/$contentId'));
  }

  // Admin
  Future<Map<String, dynamic>> getPendingUsers() async {
    return _executeApiCall(_get(ApiEndpoints.adminPendingUsers));
  }

  Future<Map<String, dynamic>> approveUser(int userId) async {
    return _executeApiCall(_post('${ApiEndpoints.adminApproveUser}/$userId'),
        successKey: 'user', dataMapper: (d) => User.fromJson(d));
  }

  Future<Map<String, dynamic>> rejectUser(int userId) async {
    return _executeApiCall(_delete('${ApiEndpoints.adminRejectUser}/$userId'));
  }

  Future<Map<String, dynamic>> getSessionLogs() async {
    return _executeApiCall(_get(ApiEndpoints.adminSessionLogs));
  }

  Future<Map<String, dynamic>> adminGetContent() async {
    return _executeApiCall(_get(ApiEndpoints.adminViewContent));
  }

  Future<Map<String, dynamic>> adminDeleteContent(int contentId) async {
    return _executeApiCall(
        _delete('${ApiEndpoints.adminDeleteContent}/$contentId'));
  }

  Future<Map<String, dynamic>> getClientAvailabilities() async {
    try {
      // Since the response is a direct list, we cannot use _handleRequest as is.
      final uri = Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.clientAvailabilities}');
      final response = await http.get(uri, headers: await _getHeaders());
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        // The endpoint returns a direct list, so we wrap it for consistency.
        return {'success': true, 'data': data};
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'An unknown error occurred');
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateSessionStatus(
      String sessionId, String status) async {
    return _executeApiCall(
        _patch('/sessions/$sessionId/status', body: {'status': status}));
  }

  // Chat
  Future<Map<String, dynamic>> getMessages(int sessionId) async {
    try {
      final result = await _get('${ApiEndpoints.getMessages}/$sessionId');
      if (result['messages'] != null && result['messages'] is List) {
        final messagesList = (result['messages'] as List)
            .map((item) => ChatMessage.fromJson(item))
            .toList();
        return {'success': true, 'messages': messagesList};
      } else {
        return {'success': true, 'messages': <ChatMessage>[]};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendMessage(
      int sessionId, String message) async {
    return _executeApiCall(
        _post(ApiEndpoints.sendMessage,
            body: {'session_id': sessionId, 'message': message}),
        successKey: 'data',
        dataMapper: (d) => ChatMessage.fromJson(d));
  }

  // Multipart special case
  Future<Map<String, dynamic>> addContent({
    required String title,
    required String description,
    required int contentTypeId,
    required String type,
    String? filePath,
  }) async {
    try {
      var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              '${ApiEndpoints.baseUrl}${ApiEndpoints.professionalAddContent}'));

      request.headers.addAll(await _getHeaders(isMultipart: true));
      request.fields.addAll({
        'title': title,
        'description': description,
        'content_type_id': contentTypeId.toString(),
        'type': type
      });

      if (filePath != null &&
          filePath.isNotEmpty &&
          await File(filePath).exists()) {
        request.files
            .add(await http.MultipartFile.fromPath('file_path', filePath));
      }

      final response = await http.Response.fromStream(await request.send());
      final data = await _handleRequest(Future.value(response));
      return {'success': true, 'data': Content.fromJson(data['data'])};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
