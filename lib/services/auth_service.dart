import 'package:firebase_auth/firebase_auth.dart';

/// Centralized Firebase Authentication service.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Currently signed-in user (null if not authenticated).
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes (login/logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
