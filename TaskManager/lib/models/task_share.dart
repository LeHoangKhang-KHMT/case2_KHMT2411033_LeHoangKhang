class Person {
  final String id;
  final String fullName;
  final String email;
  final bool isPrimary;

  Person({
    required this.id,
    required this.fullName,
    required this.email,
    this.isPrimary = false,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'].toString(),
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        isPrimary: (json['isPrimary'] ?? false) as bool,
      );
}

class TaskShare {
  final String id;
  final String permission;
  final Person user;

  TaskShare({required this.id, required this.permission, required this.user});

  factory TaskShare.fromJson(Map<String, dynamic> json) => TaskShare(
        id: json['id'].toString(),
        permission: json['permission'] as String,
        user: Person.fromJson(json['user'] as Map<String, dynamic>),
      );

  String get permissionLabel => permission == 'editor' ? 'Chỉnh sửa' : 'Chỉ xem';
}