import 'package:psychology_support_platform/models/user.dart';

class Availability {
  final int id;
  final int professionalId;
  final String availableDate;
  final String startTime;
  final String endTime;
  final User professional;

  Availability({
    required this.id,
    required this.professionalId,
    required this.availableDate,
    required this.startTime,
    required this.endTime,
    required this.professional,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      id: json['id'],
      professionalId: json['professional_id'],
      availableDate: json['available_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      professional: User.fromJson(json['professional']),
    );
  }
}
