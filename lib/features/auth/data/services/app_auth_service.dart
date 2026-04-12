import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AIImageProAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // NOTE: If GoogleSignIn() constructor is reported as missing, 
  // ensure you are using the latest version of the google_sign_in package.
  // In some versions, you might need to use GoogleSignIn.standard() or similar.
  final google_auth.GoogleSignIn _googleSignIn = google_auth.GoogleSignIn.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 7.2.0+ uses authenticate() instead of signIn()
      final googleUser = await _googleSignIn.authenticate();

      // In 7.2.0+, authentication and authorization are separate.
      final googleAuth = googleUser.authentication;
      
      // If we need the accessToken (for Google APIs or extra validation), we must authorize explicitly.
      final authorized = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorized.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('AuthService: Google Sign-In error: $e');
      rethrow;
    }
  }

  // Register with Email
  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Login with Email
  Future<UserCredential> loginWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('AuthService: Sign-out error: $e');
    }
  }

  // Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('AuthService: Anonymous sign-in failed: $e');
      return null;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('AuthService: Password reset error: $e');
      rethrow;
    }
  }
}
