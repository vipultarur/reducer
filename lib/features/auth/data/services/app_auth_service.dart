import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AIImageProAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // NOTE: If GoogleSignIn() constructor is reported as missing, 
  // ensure you are using the latest version of the google_sign_in package.
  // In some versions, you might need to use GoogleSignIn.standard() or similar.
  // Standard GoogleSignIn instance is now managed via singleton in v7.x.x

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Start the interactive sign-in flow (v7.x.x uses instance.authenticate())
      final googleUser = await google_auth.GoogleSignIn.instance.authenticate();
 
      // 3. Obtain authorization and authentication tokens
      final auth = googleUser.authentication;
      final authorized = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);
 
      // 4. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorized.accessToken,
        idToken: auth.idToken,
      );
 
      // 5. Once signed in, return the UserCredential
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
        google_auth.GoogleSignIn.instance.signOut(),
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
