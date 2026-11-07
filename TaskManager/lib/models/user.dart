class User {
  final String id;
  final String fullName;
  final String email;
  final String avatarUrl;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'].toString(),
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        avatarUrl: (json['avatarUrl'] ?? '') as String,
      );
}