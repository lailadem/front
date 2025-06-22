import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color lightPurple = Color(0xFFE8EAF6);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color.fromARGB(255, 51, 51, 51);
  static const Color textSecondary = Color(0xFF666666);
  static const Color darkGray = Color(0xFF555555);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
  static const Color warningOrange = Color(0xFFFF9800);
}

class ApiEndpoints {
  static const String baseUrl = 'https://805c-185-165-240-84.ngrok-free.app';

  // Auth & User
  static const String register = '/api/register';
  static const String login = '/api/login';
  static const String logout = '/api/logout';
  static const String userProfile = '/api/account';
  static const String updateAccount = '/api/update-account';
  static const String updatePassword = '/api/update-password';
  static const String deleteAccount = '/api/delete-account';

  // Client
  static const String clientSessions = '/api/client/my-sessions';
  static const String bookSession = '/api/client/book-session';
  static const String clientCancelSession = '/api/client/cancel-my-session';
  static const String clientDeleteSession = '/api/client/delete-session';
  static const String clientJoinSession = '/api/client/join-session';
  static const String clientFeedback = '/api/client/feedback';
  static const String clientAvailabilities = '/api/client/availabilities';

  // Professional
  static const String professionalUpcomingSessions =
      '/api/professional/upcoming-sessions';
  static const String professionalPastSessions =
      '/api/professional/past-sessions';
  static const String professionalJoinSession =
      '/api/professional/join-session';
  static const String professionalCompleteSession =
      '/api/professional/complete-session';
  static const String professionalCancelSession =
      '/api/professional/cancel-session';
  static const String professionalAvailability =
      '/api/professional/availability';

  // Professional Content
  static const String professionalViewContent =
      '/api/professional/view_content';
  static const String professionalAddContent = '/api/professional/add-content';
  static const String professionalUpdateContent =
      '/api/professional/update-content';
  static const String professionalDeleteContent =
      '/api/professional/delete-content';

  // Generic User Content
  static const String userContent = '/api/user/content';
  static const String userContentTypes = '/api/user/content-types';

  // Admin
  static const String adminPendingUsers = '/api/admin/pending-users';
  static const String adminApproveUser = '/api/admin/approve-user';
  static const String adminRejectUser = '/api/admin/reject-user';
  static const String adminSessionLogs = '/api/admin/session-logs';
  static const String adminViewContent = '/api/admin/view-content';
  static const String adminDeleteContent = '/api/admin/delete-content';

  // Messaging
  static const String getMessages = '/api/messages-view';
  static const String sendMessage = '/api/messages';
}

class AppConstants {
  static const String appName = 'Psychology Support Platform';
  static const String appVersion = '1.0.0';

  // Session Types
  static const String sessionTypeChat = 'chat';
  static const String sessionTypeVoice = 'voice';

  // User Roles
  static const String roleClient = 'client';
  static const String rolePsychologist = 'psychologist';
  static const String roleVolunteer = 'volunteer';
  static const String roleAdmin = 'admin';

  // Content Types
  static const String contentTypeArticle = 'article';
  static const String contentTypeVideo = 'video';
  static const String contentTypePDF = 'PDF';

  // Session Status
  static const String statusScheduled = 'scheduled';
  static const String statusOngoing = 'ongoing';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
}

class SharedPrefsKeys {
  static const String token = 'auth_token';
  static const String userData = 'user_data';
  static const String isLoggedIn = 'is_logged_in';
  static const String userRole = 'user_role';
}
