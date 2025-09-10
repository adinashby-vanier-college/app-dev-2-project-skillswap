import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Authentication service handling email, social logins, and user management.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  factory AuthService() => instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '918028320436-it64jqc23hgb2t1b5l6c9gtblueej716.apps.googleusercontent.com',
  );
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  /// Signs in user with email and password.
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
      debugPrint('[AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Unknown error: $e');
      throw Exception('unknown-error');
    }
  }

  /// Creates new user account with email and password.
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
      debugPrint('[AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Unknown error: $e');
      throw Exception('unknown-error');
    }
  }

  /// Signs out user from all authentication providers.
  Future<void> signOut() async {
    debugPrint('[AuthService] Signing out from all providers...');
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await _facebookAuth.logOut();
    await _auth.signOut();
    debugPrint('[AuthService] Sign out complete.');
  }

  User? get currentUser => _auth.currentUser;
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Sends verification email to current signed-in user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No signed-in user');
    await user.sendEmailVerification();
    debugPrint('[AuthService] Verification email sent to ${user.email ?? "unknown"}');
  }

  /// Reloads user and returns email verification status.
  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    debugPrint('[AuthService] Email verified status: ${refreshed?.emailVerified}');
    return refreshed?.emailVerified ?? false;
  }

  /// Signs in user with Google account.
  Future<User> signInWithGoogle() async {
    debugPrint('[AuthService] signInWithGoogle called');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('google-sign-in-cancelled');
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      debugPrint('[AuthService] Google sign in success, uid=${result.user?.uid}');
      return result.user!;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Google sign-in FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Google sign-in error: $e');
      throw Exception('google-sign-in-error');
    }
  }

  /// Signs in user with Facebook account.
  Future<User> signInWithFacebook() async {
    debugPrint('[AuthService] signInWithFacebook called');
    try {
      final LoginResult result = await _facebookAuth.login();
      if (result.status == LoginStatus.cancelled) {
        throw Exception('facebook-sign-in-cancelled');
      }
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw Exception('facebook-sign-in-failed');
      }
      final OAuthCredential facebookCredential = 
          FacebookAuthProvider.credential(result.accessToken!.tokenString);
      final userCredential = await _auth.signInWithCredential(facebookCredential);
      debugPrint('[AuthService] Facebook sign in success, uid=${userCredential.user?.uid}');
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Facebook sign-in FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Facebook sign-in error: $e');
      throw Exception('facebook-sign-in-error');
    }
  }

  /// Signs in user with X (Twitter) account.
  Future<User> signInWithTwitter() async {
    debugPrint('[AuthService] signInWithTwitter called');
    try {
      final twitterProvider = TwitterAuthProvider();
      final result = await _auth.signInWithProvider(twitterProvider);
      debugPrint('[AuthService] Twitter sign in success, uid=${result.user?.uid}');
      return result.user!;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Twitter sign-in FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Twitter sign-in error: $e');
      throw Exception('twitter-sign-in-error');
    }
  }

}
