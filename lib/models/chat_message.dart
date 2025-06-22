class ChatMessage {
  final int id;
  final int sessionId;
  final int senderId;
  final String senderName;
  final String message;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;

    return ChatMessage(
      id: json['id'] ?? 0,
      sessionId: int.tryParse(json['session_id']?.toString() ?? '') ?? 0,
      senderId: int.tryParse(json['sender_id']?.toString() ?? '') ??
          (sender?['id'] as int? ?? 0),
      senderName: sender?['name'] as String? ?? 'Unknown User',
      message: json['message'] as String? ?? '',
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
