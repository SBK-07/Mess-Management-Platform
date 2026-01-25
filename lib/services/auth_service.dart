import '../models/user.dart';
import '../utils/dummy_data.dart';

/// Authentication service for handling user login.
/// 
/// Uses dummy data for authentication - no real backend required.
class AuthService {
  // Private constructor for singleton pattern
  AuthService._();
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  /// Authenticate user with username and password.
  /// 
  /// Returns [User] if credentials match, null otherwise.
  User? login(String username, String password) {
    // Find user by username
    final user = DummyData.findUserByUsername(username);
    
    if (user == null) {
      return null; // User not found
    }

    // Check password match
    if (user.password == password) {
      return user;
    }

    return null; // Password mismatch
  }

  /// Validate if username exists in the system.
  bool userExists(String username) {
    return DummyData.findUserByUsername(username) != null;
  }

  /// Get user by ID
  User? getUserById(String id) {
    try {
      return DummyData.users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}
