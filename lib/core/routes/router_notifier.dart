import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/features/auth/presentation/providers/auth_providers.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/features/exif/presentation/providers/exif_providers.dart';

/// A notifier that manages the redirect logic for GoRouter based on authentication state.
/// This class implements [Listenable] so GoRouter can react to state changes.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  User? _user;

  RouterNotifier(this._ref) {
    // Listen to auth state changes and notify GoRouter
    _ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      if (next is AsyncData) {
        _user = next.value;
        notifyListeners();
      }
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.matchedLocation;
    final isAuthRoute = path == '/login' || path == '/register';
    final isLoggedIn = _user != null && !_user!.isAnonymous;
    final isPro = _ref.read(premiumControllerProvider).isPro;
    final requestedRedirect = state.uri.queryParameters['redirect'];

    // Guest mode is allowed across the app, including profile.

    // Hard-gate premium-only routes.
    final credits = _ref.read(exifCreditProvider).availableCredits;
    
    if (path == '/bulk-editor' && !isPro) {
      return '/premium';
    }
    
    if (path == '/exif-eraser' && !isPro && credits <= 0) {
      return '/premium';
    }

    // Keep authenticated users out of auth forms.
    if (isAuthRoute && isLoggedIn) {
      if (_isSafeRedirectTarget(requestedRedirect)) {
        return requestedRedirect;
      }
      return '/';
    }

    return null;
  }

  bool _isSafeRedirectTarget(String? target) {
    if (target == null || target.isEmpty) return false;
    if (!target.startsWith('/')) return false;
    if (target == '/login' || target == '/register' || target == '/splash') {
      return false;
    }
    return true;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);
