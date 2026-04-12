import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reducer/features/auth/data/services/app_auth_service.dart';
import 'package:reducer/features/auth/data/services/user_service.dart';
import 'package:reducer/features/auth/data/services/cloudinary_service.dart';
import 'package:reducer/features/auth/domain/models/user_model.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';

// Service Providers
final authServiceProvider = Provider((ref) => AIImageProAuthService());
final userServiceProvider = Provider((ref) => UserService());
final cloudinaryServiceProvider = Provider((ref) => CloudinaryService());

// Auth State Provider
final authProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Alias for backward compatibility
final authStateProvider = authProvider;

// User Data Provider (Firestore)
final userProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authProvider).value;
  if (authState == null) return Stream.value(null);
  return ref.watch(userServiceProvider).streamUser(authState.uid);
});

// Auth Controller Provider
final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<bool> {
  final Ref _ref;

  AuthController(this._ref) : super(false);

  Future<void> register(String name, String email, String password) async {
    state = true;
    try {
      final userCredential = await _ref.read(authServiceProvider).registerWithEmail(email, password);
      final user = userCredential.user;
      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          name: name,
        );
        await _ref.read(userServiceProvider).saveUser(userModel);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    } finally {
      state = false;
    }
  }

  Future<void> login(String email, String password) async {
    state = true;
    try {
      await _ref.read(authServiceProvider).loginWithEmail(email, password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Login failed: $e';
    } finally {
      state = false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = true;
    try {
      final userCredential = await _ref.read(authServiceProvider).signInWithGoogle();
      final user = userCredential?.user;
      if (user != null) {
        final existingUser = await _ref.read(userServiceProvider).getUser(user.uid);
        if (existingUser == null) {
          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'New User',
            profileImageUrl: user.photoURL,
          );
          await _ref.read(userServiceProvider).saveUser(userModel);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Google Sign-In failed: $e';
    } finally {
      state = false;
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }

  Future<void> logout() async {
    state = true;
    try {
      await _ref.read(authServiceProvider).signOut();
      await _ref.read(premiumControllerProvider.notifier).clearProStatus();
    } finally {
      state = false;
    }
  }

  Future<void> updateProfileImage(File imageFile) async {
    final currentUser = _ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    state = true;
    try {
      final imageUrl = await _ref.read(cloudinaryServiceProvider).uploadImage(imageFile, userId: currentUser.uid);
      if (imageUrl != null) {
        await _ref.read(userServiceProvider).updateFields(currentUser.uid, {
          'profileImageUrl': imageUrl,
        });
      } else {
        throw 'Failed to upload image to Cloudinary.';
      }
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }
  
  Future<void> updateName(String name) async {
    final currentUser = _ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    state = true;
    try {
      await _ref.read(userServiceProvider).updateFields(currentUser.uid, {
        'name': name,
      });
    } finally {
      state = false;
    }
  }
}
