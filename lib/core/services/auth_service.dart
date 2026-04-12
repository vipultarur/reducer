import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the Auth Service
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider for the current User state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// A robust Firebase Authentication service.
/// 
/// Handles sign-in, sign-out, and user state management.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of user auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user.
  User? get currentUser => _auth.currentUser;

  /// Sign in anonymously.
  /// 
  /// Useful for persistent storage before user creates an account.
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('[AuthService] Anonymous sign-in failed: $e');
      return null;
    }
  }

  /// Sign in with Email and Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
    } catch (e) {
      debugPrint('[AuthService] Email sign-in failed: $e');
      rethrow;
    }
  }

  /// Register with Email and Password
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
    } catch (e) {
      debugPrint('[AuthService] Email registration failed: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] Sign-out failed: $e');
    }
  }
}
