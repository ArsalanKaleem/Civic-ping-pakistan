import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';

/// Authentication state for both apps.
///
/// Modes:
///  * Firebase (Google popup on web, or email/password) — production identity.
///  * Guest — a backend-issued anonymous token so citizens can report without
///    an account. Guests can still confirm reports (one per identity).
class AuthService extends ChangeNotifier {
  AuthService(this._api) {
    _api.tokenProvider = _currentToken;
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  final ApiClient _api;
  static const _guestKey = 'guest_token';
  String? _guestToken;

  User? get firebaseUser => FirebaseAuth.instance.currentUser;
  bool get isSignedIn => firebaseUser != null || _guestToken != null;
  bool get isGuest => firebaseUser == null && _guestToken != null;
  String get displayName =>
      firebaseUser?.displayName ?? firebaseUser?.email ?? 'Guest';

  Future<String?> _currentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user.getIdToken();
    return _guestToken;
  }

  Future<void> restoreGuest() async {
    final prefs = await SharedPreferences.getInstance();
    _guestToken = prefs.getString(_guestKey);
    notifyListeners();
  }

  // --- Firebase flows ---------------------------------------------------- //

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // Browser: Firebase popup flow.
      final provider = GoogleAuthProvider()..addScope('email');
      await FirebaseAuth.instance.signInWithPopup(provider);
    } else {
      // Android/iOS: native Google flow -> exchange for a Firebase credential.
      // Requires the app's SHA-1 fingerprint registered in Firebase (Android).
      final account = await GoogleSignIn(scopes: const ['email']).signIn();
      if (account == null) {
        throw FirebaseAuthException(code: 'popup-closed-by-user');
      }
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    }
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email.trim(), password: password);
    notifyListeners();
  }

  Future<void> registerWithEmail(
      String email, String password, String? name) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    if (name != null && name.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(name.trim());
    }
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

  // --- Guest flow --------------------------------------------------------- //

  Future<void> continueAsGuest() async {
    final data = await _api.post('/auth/anonymous');
    _guestToken = data['access_token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestKey, _guestToken!);
    notifyListeners();
  }

  // --- Shared ------------------------------------------------------------- //

  /// Backend profile (includes is_admin, resolved server-side).
  Future<Map<String, dynamic>> me() async =>
      await _api.get('/auth/me') as Map<String, dynamic>;

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    await FirebaseAuth.instance.signOut();
    _guestToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
    notifyListeners();
  }

  /// Human-friendly Firebase error messages.
  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' => 'Password must be at least 6 characters.',
        'invalid-email' => 'That email address looks invalid.',
        'popup-closed-by-user' => 'Sign-in was cancelled.',
        'network-request-failed' => 'Network error — check your connection.',
        _ => e.message ?? 'Sign-in failed. Please try again.',
      };
    }
    return e.toString();
  }
}
