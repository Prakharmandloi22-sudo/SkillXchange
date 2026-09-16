enum MessageType { text, audioCall, videoCall }

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? duration;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.duration,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime parsedTime;
    final dynamic timestamp = json['timestamp'] ?? json['createdAt'];
    
    if (timestamp is String) {
      parsedTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      parsedTime = DateTime.now();
    }

    return MessageModel(
      id: id.isEmpty ? (json['_id'] ?? json['id'] ?? '').toString() : id,
      senderId: (json['senderId'] ?? json['sender_id'] ?? json['sender'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      timestamp: parsedTime,
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == (json['type'] ?? 'MessageType.text'),
        orElse: () => MessageType.text,
      ),
      duration: json['duration']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'type': type.toString(),
      'duration': duration,
    };
  }
}
