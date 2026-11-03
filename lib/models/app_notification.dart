import 'dart:convert';

enum AppNotificationType {
  info,
  success,
  warning,
  error,
  quarterProgress,
  quarterCompleted,
  calendarScheduled,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final AppNotificationType type;
  final bool isRead;
  final Map<String, dynamic>? payload;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = AppNotificationType.info,
    this.isRead = false,
    this.payload,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    AppNotificationType? type,
    bool? isRead,
    Map<String, dynamic>? payload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
      'payload': payload,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: AppNotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AppNotificationType.info,
      ),
      isRead: map['isRead'] == true,
      payload: map['payload'] != null ? Map<String, dynamic>.from(map['payload']) : null,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory AppNotification.fromJson(String source) =>
      AppNotification.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
