import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:reducer/features/gallery/data/models/history_item.dart';
import 'package:reducer/core/services/sync_service.dart';

class HistoryState {
  final List<HistoryItem> items;
  final bool isLoading;

  const HistoryState({
    this.items = const [],
    this.isLoading = false,
  });

  HistoryState copyWith({
    List<HistoryItem>? items,
    bool? isLoading,
  }) {
    return HistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final historyControllerProvider =
    AutoDisposeAsyncNotifierProvider<HistoryController, HistoryState>(
      HistoryController.new,
    );

class HistoryController extends AutoDisposeAsyncNotifier<HistoryState> {
  static const _secureStorageKey = 'edit_history_secure_v1';
  static const _sharedPrefsKey = 'edit_history_v3';
  static const _legacyKey = 'edit_history_v2';
  static const _secureStorage = FlutterSecureStorage();

  @override
  Future<HistoryState> build() async {
    // Fix: Async build initializes state before any method reads it.
    final items = await _loadItemsFromStorage();
    return HistoryState(items: items, isLoading: false);
  }

  Future<void> loadHistory() async {
    // Ensuring state is initialized.
    await future;
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final items = await _loadItemsFromStorage();
      return HistoryState(items: items, isLoading: false);
    });
  }

  Future<void> addItem(HistoryItem item) async {
    final current = await future;
    
    final updatedItems = [item, ...current.items]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = AsyncValue.data(
      current.copyWith(items: updatedItems, isLoading: false),
    );

    final syncService = ref.read(syncServiceProvider);
    unawaited(syncService.syncItem(item));

    unawaited(_saveToStorage(updatedItems));
  }

  Future<void> removeItem(String id) async {
    final current = await future;
    
    final updatedItems = current.items
        .where((item) => item.id != id)
        .toList(growable: false);

    state = AsyncValue.data(
      current.copyWith(items: updatedItems, isLoading: false),
    );

    final syncService = ref.read(syncServiceProvider);
    unawaited(syncService.deleteItem(id));

    unawaited(_saveToStorage(updatedItems));
  }

  Future<void> clearAll() async {
    // Guarantee initialization
    await future;
    
    state = const AsyncValue.data(
      HistoryState(items: [], isLoading: false),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sharedPrefsKey);
  }

  Future<List<HistoryItem>> _loadItemsFromStorage() async {
    try {
      // 1. Migration from insecure/secure storage if necessary
      await _migrateToSharedPreferences();

      // 2. Read from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final historyJsonRaw = prefs.getString(_sharedPrefsKey);
      
      if (historyJsonRaw == null || historyJsonRaw.isEmpty) {
        return const [];
      }
      
      final historyJson = (jsonDecode(historyJsonRaw) as List).cast<String>();
      return compute(_decodeHistory, historyJson);
    } catch (e) {
      debugPrint('[Storage] Failed to load history: $e');
      return const [];
    }
  }

  Future<void> _saveToStorage(List<HistoryItem> items) async {
    try {
      final historyJson = await compute(_encodeHistory, items);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sharedPrefsKey,
        jsonEncode(historyJson),
      );
    } catch (e) {
      debugPrint('[Storage] Failed to save history: $e');
    }
  }

  Future<void> _migrateToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // If we already have the new key, no migration needed
      if (prefs.containsKey(_sharedPrefsKey)) return;

      String? historyToMigrate;

      // 1. Try to get from Secure Storage (v1)
      try {
        historyToMigrate = await _secureStorage.read(key: _secureStorageKey);
      } catch (e) {
        debugPrint('[Storage] Could not read from secure storage: $e');
      }

      // 2. If secure storage is empty, check old legacy key (v2)
      if (historyToMigrate == null || historyToMigrate.isEmpty) {
        if (prefs.containsKey(_legacyKey)) {
          final legacyList = prefs.getStringList(_legacyKey);
          if (legacyList != null && legacyList.isNotEmpty) {
            historyToMigrate = jsonEncode(legacyList);
          }
        }
      }

      // 3. If we found data, save it to the new key
      if (historyToMigrate != null && historyToMigrate.isNotEmpty) {
        debugPrint('[Storage] Migrating history to SharedPreferences...');
        await prefs.setString(_sharedPrefsKey, historyToMigrate);
      }

      // 4. Cleanup old storage
      await _secureStorage.delete(key: _secureStorageKey);
      await prefs.remove(_legacyKey);
      
      debugPrint('[Storage] History migration complete.');
    } catch (e) {
      debugPrint('[Storage] Migration failed: $e');
    }
  }
}

List<String> _encodeHistory(List<HistoryItem> items) {
  return items.map((item) => jsonEncode(item.toJson())).toList(growable: false);
}

List<HistoryItem> _decodeHistory(List<String> historyJson) {
  final items = <HistoryItem>[];

  for (final rawItem in historyJson) {
    try {
      final decoded = jsonDecode(rawItem) as Map<String, dynamic>;
      items.add(HistoryItem.fromJson(decoded));
    } catch (e) {
      debugPrint('Skipping corrupt history entry: $e');
    }
  }

  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return items;
}

