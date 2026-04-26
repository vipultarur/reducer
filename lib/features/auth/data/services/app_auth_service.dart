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
      // 1. Start the interactive sign-in flow
      // authenticate() returns non-nullable in v7.x.x; throws GoogleSignInException on cancel
      final googleUser = await google_auth.GoogleSignIn.instance.authenticate();

      // 2. Get idToken from authentication (only contains idToken in v7.x.x)
      final auth = googleUser.authentication;

      // 3. Get accessToken via authorization (separate from authentication in v7.x.x)
      final authorized = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

      // 4. Create Firebase credential from Google tokens
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorized.accessToken,
        idToken: auth.idToken,
      );

      // 5. Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credential);
    } on google_auth.GoogleSignInException catch (e) {
      // User cancelled the sign-in flow
      if (e.code == google_auth.GoogleSignInExceptionCode.canceled ||
          e.code == google_auth.GoogleSignInExceptionCode.interrupted) {
        debugPrint('AuthService: Google Sign-In cancelled by user');
        return null;
      }
      debugPrint('AuthService: Google Sign-In exception: ${e.code} - ${e.description}');
      rethrow;
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

  // Delete Account (Mandatory for App Store compliance)
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Attempt deletion
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        debugPrint('AuthService: Token stale. Attempting re-authentication...');
        final providerData = _auth.currentUser?.providerData ?? [];
        final hasGoogle = providerData.any((p) => p.providerId == 'google.com');
        
        if (hasGoogle) {
           final credential = await signInWithGoogle();
           if (credential != null) {
              // Retry deletion after successful re-auth
              await _auth.currentUser?.delete();
              return;
           }
        }
      }
      debugPrint('AuthService: Account deletion error: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected account deletion error: $e');
      rethrow;
    }
  }
}

