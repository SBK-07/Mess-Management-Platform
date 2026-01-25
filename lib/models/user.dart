/// User model representing a student or admin in the mess management system.
/// 
/// This model holds user authentication and profile information.
class User {
  final String id;
  final String name;
  final String username;
  final String password;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.isAdmin = false,
  });

  /// Factory constructor to create a User from a Map (for future extensions)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      isAdmin: map['isAdmin'] as bool? ?? false,
    );
  }

  /// Convert User to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'isAdmin': isAdmin,
    };
  }

  @override
  String toString() => 'User(id: $id, name: $name, isAdmin: $isAdmin)';
}
