class AppNotification {
  final String id;
  final String? taskId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.taskId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['_id'].toString(),
        taskId: json['taskId']?.toString(),
        type: json['type'] as String,
        title: json['title'] as String,
        message: (json['message'] ?? '') as String,
        isRead: (json['isRead'] ?? false) as bool,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String).toLocal(),
      );
}