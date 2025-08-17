import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // --- Singleton pattern ---
  AuthService._(); // private constructor
  static final AuthService instance = AuthService._();

  factory AuthService() => instance;

  // --- Firebase instance ---
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Existing methods (unchanged) ---

  Future<User> signInWithEmail(String email, String password) async {
    debugPrint('[AuthService] signInWithEmail called, email=$email');
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[AuthService] Sign in success, uid=${result.user?.uid}');
      return result.user!;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Unknown error: $e');
      throw Exception('unknown-error');
    }
  }

  Future<User> signUpWithEmail(String email, String password) async {
    debugPrint('[AuthService] signUpWithEmail called, email=$email');
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[AuthService] Sign up success, uid=${result.user?.uid}');
      return result.user!;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Unknown error: $e');
      throw Exception('unknown-error');
    }
  }

  Future<void> signOut() async {
    debugPrint('[AuthService] Signing out...');
    await _auth.signOut();
    debugPrint('[AuthService] Sign out complete.');
  }

  User? get currentUser => _auth.currentUser;

  // --- New methods for email verification ---

  /// Send verification email to current signed-in user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No signed-in user');
    await user.sendEmailVerification();
    debugPrint(
        '[AuthService] Verification email sent to ${user.email ?? "unknown"}');
  }

  /// Reload user and check whether email is verified
  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    debugPrint(
        '[AuthService] Email verified status: ${refreshed?.emailVerified}');
    return refreshed?.emailVerified ?? false;
  }

  /// Convenience getter for current user email
  String? get currentUserEmail => _auth.currentUser?.email;
}
