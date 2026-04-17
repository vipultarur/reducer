import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:reducer/features/auth/domain/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserService();

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Create or update user document with the exact schema contract.
  ///
  /// Document ID = Firebase UID.
  /// Ensures required defaults and keeps subscription fields intact on update.
  Future<void> createOrUpdateUserFromAuth({
    required User user,
    required String email,
    required String name,
    String? profileImageUrl,
  }) async {
    final docRef = _usersCollection.doc(user.uid);

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final existing = snap.data() ?? const <String, dynamic>{};

        final resolvedEmail = email.trim().isNotEmpty
            ? email.trim()
            : (user.email ?? (existing['email'] as String? ?? ''));
        final resolvedName = name.trim().isNotEmpty
            ? name.trim()
            : (existing['name'] as String? ?? user.displayName ?? 'New User');

        final payload = <String, dynamic>{
          'uid': user.uid,
          'email': resolvedEmail,
          'name': resolvedName,
          'profileImageUrl':
              profileImageUrl ?? existing['profileImageUrl'] ?? user.photoURL,
          'subscriptionStatus': existing['subscriptionStatus'] ?? 'free',
          'productId': existing['productId'],
          'basePlanId': existing['basePlanId'],
          'purchaseToken': existing['purchaseToken'],
          'orderId': existing['orderId'],
          'subscriptionStartDate': existing['subscriptionStartDate'],
          'subscriptionEndDate': existing['subscriptionEndDate'],
          'expiryDate': existing['expiryDate'],
          'autoRenewing': existing['autoRenewing'] ?? false,
          'priceAmount': existing['priceAmount'],
          'priceCurrencyCode': existing['priceCurrencyCode'],
          'billingPeriod': existing['billingPeriod'],
          'aiImagesGenerated': existing['aiImagesGenerated'] ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (!snap.exists || existing['createdAt'] == null) {
          payload['createdAt'] = FieldValue.serverTimestamp();
        } else {
          payload['createdAt'] = existing['createdAt'];
        }

        tx.set(docRef, payload, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('UserService: createOrUpdateUserFromAuth error: $e');
      rethrow;
    }
  }

  /// Create or update user document from model.
  Future<void> saveUser(UserModel user) async {
    try {
      await _usersCollection
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('UserService: saveUser error: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('UserService: getUser error: $e');
      rethrow;
    }
  }

  Stream<UserModel?> streamUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateFields(String uid, Map<String, dynamic> fields) async {
    try {
      await _usersCollection.doc(uid).set({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('UserService: updateFields error: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(
    String uid,
    Map<String, dynamic> subData,
  ) async {
    try {
      await _usersCollection.doc(uid).set({
        ...subData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('UserService: updateSubscription error: $e');
      rethrow;
    }
  }
}
