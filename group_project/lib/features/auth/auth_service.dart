import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'auth_exceptions.dart';
import '../../utils/app_logger.dart';

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
    AppLogger.auth('signInWithEmail called, email=$email');
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      AppLogger.auth('Sign in success, uid=${result.user?.uid}');
      return result.user!;
    } catch (e) {
      AppLogger.error('Sign in error', tag: 'AUTH', error: e);
      throw AuthExceptionMapper.mapFirebaseException(
        e, 
        'Failed to sign in. Please check your credentials.'
      );
    }
  }

  /// Creates new user account with email and password.
  Future<User> signUpWithEmail(String email, String password) async {
    AppLogger.auth('signUpWithEmail called, email=$email');
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      AppLogger.auth('Sign up success, uid=${result.user?.uid}');
      return result.user!;
    } catch (e) {
      AppLogger.error('Sign up error', tag: 'AUTH', error: e);
      throw AuthExceptionMapper.mapFirebaseException(
        e, 
        'Failed to create account. Please try again.'
      );
    }
  }

  /// Signs out user from all authentication providers.
  Future<void> signOut() async {
    AppLogger.auth('Signing out from all providers...');
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await _facebookAuth.logOut();
    await _auth.signOut();
    AppLogger.auth('Sign out complete.');
  }

  User? get currentUser => _auth.currentUser;
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Sends verification email to current signed-in user.
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthExceptionMapper.mapFirebaseException(
          Exception('No signed-in user'),
          'No user is currently signed in. Please sign in first.'
        );
      }
      await user.sendEmailVerification();
      AppLogger.auth('Verification email sent to ${user.email ?? "unknown"}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthExceptionMapper.mapFirebaseException(
        e,
        'Failed to send verification email. Please try again.'
      );
    }
  }

  /// Reloads user and returns email verification status.
  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    AppLogger.auth('Email verified status: ${refreshed?.emailVerified}');
    return refreshed?.emailVerified ?? false;
  }

  /// Signs in user with Google account.
  Future<User> signInWithGoogle() async {
    AppLogger.auth('signInWithGoogle called');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthExceptionMapper.mapFirebaseException(
          Exception('google-sign-in-cancelled'),
          'Google sign-in was cancelled.'
        );
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      AppLogger.auth('Google sign in success, uid=${result.user?.uid}');
      return result.user!;
    } catch (e) {
      AppLogger.error('Google sign-in error', tag: 'AUTH', error: e);
      throw AuthExceptionMapper.mapFirebaseException(
        e,
        'Failed to sign in with Google. Please try again.'
      );
    }
  }

  /// Signs in user with Facebook account.
  Future<User> signInWithFacebook() async {
    AppLogger.auth('signInWithFacebook called');
    try {
      final LoginResult result = await _facebookAuth.login();
      if (result.status == LoginStatus.cancelled) {
        throw AuthExceptionMapper.mapFirebaseException(
          Exception('facebook-sign-in-cancelled'),
          'Facebook sign-in was cancelled.'
        );
      }
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw AuthExceptionMapper.mapFirebaseException(
          Exception('facebook-sign-in-failed'),
          'Facebook sign-in failed. Please try again.'
        );
      }
      final OAuthCredential facebookCredential = 
          FacebookAuthProvider.credential(result.accessToken!.tokenString);
      final userCredential = await _auth.signInWithCredential(facebookCredential);
      AppLogger.auth('Facebook sign in success, uid=${userCredential.user?.uid}');
      return userCredential.user!;
    } catch (e) {
      AppLogger.error('Facebook sign-in error', tag: 'AUTH', error: e);
      throw AuthExceptionMapper.mapFirebaseException(
        e,
        'Failed to sign in with Facebook. Please try again.'
      );
    }
  }

  /// Signs in user with X (Twitter) account.
  Future<User> signInWithTwitter() async {
    AppLogger.auth('signInWithTwitter called');
    try {
      final twitterProvider = TwitterAuthProvider();
      final result = await _auth.signInWithProvider(twitterProvider);
      AppLogger.auth('Twitter sign in success, uid=${result.user?.uid}');
      return result.user!;
    } catch (e) {
      AppLogger.error('Twitter sign-in error', tag: 'AUTH', error: e);
      throw AuthExceptionMapper.mapFirebaseException(
        e,
        'Failed to sign in with Twitter. Please try again.'
      );
    }
  }

}
