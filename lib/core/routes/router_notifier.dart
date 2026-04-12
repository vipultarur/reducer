import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/features/auth/presentation/providers/auth_providers.dart';

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
    final bool loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    
    // If not logged in and not on login/register pages, redirect to login
    if (_user == null) {
      return loggingIn ? null : '/login';
    }

    // If logged in and on login/register pages, redirect to home
    if (loggingIn) {
      return '/';
    }

    // No redirect needed
    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));
