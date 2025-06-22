import 'user.dart';

class Session {
  final int id;
  final int clientId;
  final int professionalId;
  final String scheduledAt;
  final String sessionType;
  final String? status;
  final String createdAt;
  final String updatedAt;
  final User? client;
  final User? professional;

  Session({
    required this.id,
    required this.clientId,
    required this.professionalId,
    required this.scheduledAt,
    required this.sessionType,
    this.status,
    required this.createdAt,
    required this.updatedAt,
    this.client,
    this.professional,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    String? currentStatus =
        json['status'] ?? json['status_type'] ?? 'scheduled';
    final scheduledAtStr =
        json['scheduled_at'] ?? DateTime.now().toIso8601String();
    final scheduledAtDate = DateTime.tryParse(scheduledAtStr);

    // Workaround for backend sending incorrect status for upcoming sessions.
    if (scheduledAtDate != null &&
        scheduledAtDate.isAfter(DateTime.now()) &&
        currentStatus?.toLowerCase() == 'completed') {
      currentStatus = 'Confirmed';
    }

    return Session(
      id: json['id'],
      clientId: json['client_id'],
      professionalId: json['professional_id'],
      scheduledAt: scheduledAtStr,
      sessionType: json['communication_type'] ?? json['type'] ?? 'chat',
      status: currentStatus,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
      client: json['client'] != null ? User.fromJson(json['client']) : null,
      professional: json['professional'] != null
          ? User.fromJson(json['professional'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'professional_id': professionalId,
      'scheduled_at': scheduledAt,
      'session_type': sessionType,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'client': client?.toJson(),
      'professional': professional?.toJson(),
    };
  }

  Session copyWith({
    int? id,
    int? clientId,
    int? professionalId,
    String? scheduledAt,
    String? sessionType,
    String? status,
    String? createdAt,
    String? updatedAt,
    User? client,
    User? professional,
  }) {
    return Session(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      professionalId: professionalId ?? this.professionalId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      client: client ?? this.client,
      professional: professional ?? this.professional,
    );
  }
}
