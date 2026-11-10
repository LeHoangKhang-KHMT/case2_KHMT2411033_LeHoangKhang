class TaskActivity {
  final String id;
  final String action;
  final Map<String, dynamic> details;
  final DateTime? createdAt;
  final String userName;

  TaskActivity({
    required this.id,
    required this.action,
    required this.details,
    required this.createdAt,
    required this.userName,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> json) => TaskActivity(
        id: json['id'].toString(),
        action: json['action'] as String,
        details: Map<String, dynamic>.from((json['details'] ?? {}) as Map),
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String).toLocal(),
        userName: ((json['user'] as Map<String, dynamic>)['fullName'] ?? '') as String,
      );
}