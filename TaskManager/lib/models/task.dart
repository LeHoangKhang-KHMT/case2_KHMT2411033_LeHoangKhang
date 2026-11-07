class Task {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.startDate,
    this.dueDate,
    this.createdAt,
  });

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['_id'].toString(),
        title: json['title'] as String,
        description: (json['description'] ?? '') as String,
        priority: (json['priority'] ?? 'medium') as String,
        status: (json['status'] ?? 'todo') as String,
        startDate: _date(json['startDate']),
        dueDate: _date(json['dueDate']),
        createdAt: _date(json['createdAt']),
      );
}