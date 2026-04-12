import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/features/gallery/data/models/history_item.dart';
import 'package:reducer/features/auth/presentation/providers/auth_providers.dart';

/// Provider for the Sync Service
final syncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final user = ref.watch(authStateProvider).value;
  return FirestoreSyncService(user);
});

/// Service responsible for syncing edit history to the cloud.
class FirestoreSyncService {
  final User? user;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreSyncService(this.user);

  bool get isAuthenticated => user != null;

  /// Collection reference for the user's history.
  CollectionReference? get _historyCollection {
    if (user == null) return null;
    return _db.collection('users').doc(user!.uid).collection('history');
  }

  /// Sync a new history item to Firestore.
  Future<void> syncItem(HistoryItem item) async {
    if (!isAuthenticated) return;

    try {
      await _historyCollection!.doc(item.id).set(item.toJson());
      debugPrint('[SyncService] Item ${item.id} synced to cloud.');
    } catch (e) {
      debugPrint('[SyncService] Failed to sync item: $e');
    }
  }

  /// Delete a history item from Firestore.
  Future<void> deleteItem(String id) async {
    if (!isAuthenticated) return;

    try {
      await _historyCollection!.doc(id).delete();
      debugPrint('[SyncService] Item $id deleted from cloud.');
    } catch (e) {
      debugPrint('[SyncService] Failed to delete item: $e');
    }
  }

  /// Get real-time stream of history items from the cloud.
  Stream<List<HistoryItem>> get cloudHistoryStream {
    if (!isAuthenticated) return Stream.value([]);

    return _historyCollection!
        .orderBy('timestamp', descending: true)
        .limit(20) // ── OPTIMIZATION: Limit real-time sync to latest 20 items ──
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistoryItem.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Mass upload local items (useful after signing in).
  Future<void> syncLocalItems(List<HistoryItem> items) async {
    if (!isAuthenticated || items.isEmpty) return;

    final batch = _db.batch();
    for (final item in items) {
      batch.set(_historyCollection!.doc(item.id), item.toJson());
    }

    try {
      await batch.commit();
      debugPrint('[SyncService] Batch sync of ${items.length} items complete.');
    } catch (e) {
      debugPrint('[SyncService] Batch sync failed: $e');
    }
  }
}
