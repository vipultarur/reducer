import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reducer/features/auth/domain/models/user_model.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserService() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024, // 100MB limit
    );
  }

  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create or update user document
  Future<void> saveUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(
            user.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('UserService: Save user error: $e');
      rethrow;
    }
  }

  // Get user document
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('UserService: Get user error: $e');
      rethrow;
    }
  }

  // Stream of user data
  Stream<UserModel?> streamUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update specific fields (e.g., profile image URL)
  Future<void> updateFields(String uid, Map<String, dynamic> fields) async {
    try {
      await _usersCollection.doc(uid).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('UserService: Update fields error: $e');
      rethrow;
    }
  }

  // Update subscription status
  Future<void> updateSubscription(String uid, Map<String, dynamic> subData) async {
    try {
      await _usersCollection.doc(uid).update({
        ...subData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('UserService: Update subscription error: $e');
      rethrow;
    }
  }
}
