class Task {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final String? createdByName;
  final List<String> assigneeNames;
  final String? primaryAssigneeName;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.startDate,
    this.dueDate,
    this.createdAt,
    this.createdByName,
    this.assigneeNames = const [],
    this.primaryAssigneeName,
  });

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  // Backend trả về object (đã populate) ở màn hình chi tiết, trả về id ở danh sách.
  static String? _name(dynamic v) => v is Map ? v['fullName'] as String? : null;

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['_id'].toString(),
        title: json['title'] as String,
        description: (json['description'] ?? '') as String,
        priority: (json['priority'] ?? 'medium') as String,
        status: (json['status'] ?? 'todo') as String,
        startDate: _date(json['startDate']),
        dueDate: _date(json['dueDate']),
        createdAt: _date(json['createdAt']),
        createdByName: _name(json['createdBy']),
        assigneeNames: ((json['assigneeIds'] ?? []) as List)
            .map(_name)
            .whereType<String>()
            .toList(),
        primaryAssigneeName: _name(json['primaryAssigneeId']),
      );
}

class TaskAccess {
  final String role;
  final bool canEdit;
  final bool canDelete;
  final bool canUpdateStatus;
  final bool canManage;

  TaskAccess({
    required this.role,
    required this.canEdit,
    required this.canDelete,
    required this.canUpdateStatus,
    required this.canManage,
  });

  factory TaskAccess.fromJson(Map<String, dynamic> json) => TaskAccess(
        role: json['role'] as String,
        canEdit: json['canEdit'] as bool,
        canDelete: json['canDelete'] as bool,
        canUpdateStatus: json['canUpdateStatus'] as bool,
        canManage: (json['canManage'] ?? false) as bool,
      );

  String get roleLabel {
    switch (role) {
      case 'creator':
        return 'Người tạo';
      case 'primary':
        return 'Người phụ trách';
      case 'assignee':
        return 'Người được giao';
      case 'editor':
        return 'Người chỉnh sửa';
      default:
        return 'Người xem';
    }
  }
}

class TaskDetail {
  final Task task;
  final TaskAccess access;
  TaskDetail({required this.task, required this.access});
}