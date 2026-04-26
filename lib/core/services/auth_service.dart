import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/core/models/result.dart';

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
  Future<Result<UserCredential?>> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return Result.success(credential);
    } catch (e) {
      debugPrint('[AuthService] Anonymous sign-in failed: $e');
      return Result.failure('Anonymous sign-in failed. Please try again.', e);
    }
  }

  /// Sign in with Email and Password
  Future<Result<UserCredential?>> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      return Result.success(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Email sign-in failed: ${e.code}');
      return Result.failure(_mapAuthError(e.code), e);
    } catch (e) {
      return Result.failure('An unexpected error occurred.', e);
    }
  }

  /// Register with Email and Password
  Future<Result<UserCredential?>> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      return Result.success(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Email registration failed: ${e.code}');
      return Result.failure(_mapAuthError(e.code), e);
    } catch (e) {
      return Result.failure('An unexpected error occurred.', e);
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
  
  /// Delete user account (Required for Store compliance)
  Future<Result<void>> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return Result.failure('No user logged in.');
      
      await user.delete();
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Account deletion failed: ${e.code}');
      if (e.code == 'requires-recent-login') {
        return Result.failure('Please re-login to delete your account for security.', e);
      }
      return Result.failure(_mapAuthError(e.code), e);
    } catch (e) {
      return Result.failure('An unexpected error occurred during account deletion.', e);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'An account already exists for this email.';
      case 'weak-password': return 'The password provided is too weak.';
      case 'invalid-email': return 'The email address is not valid.';
      default: return 'Authentication failed: $code';
    }
  }
}

