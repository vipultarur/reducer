import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reducer/features/auth/presentation/pages/login_screen.dart';
import 'package:reducer/features/auth/presentation/pages/register_screen.dart';
import 'package:reducer/features/auth/presentation/pages/profile_screen.dart';
import 'package:reducer/core/routes/router_notifier.dart';
import 'package:reducer/features/splash/presentation/pages/splash_page.dart';
import 'package:reducer/features/home/presentation/pages/main_screen.dart';
import 'package:reducer/features/home/presentation/pages/home_page.dart';
import 'package:reducer/features/editor/presentation/pages/single_image_page.dart';
import 'package:reducer/features/bulk/presentation/pages/bulk_image_page.dart';
import 'package:reducer/features/premium/presentation/pages/premium_page.dart';
import 'package:reducer/features/gallery/presentation/pages/gallery_page.dart';
import 'package:reducer/features/exif/presentation/pages/exif_eraser_page.dart';
import 'package:reducer/features/settings/presentation/pages/settings_page.dart';
import 'package:reducer/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:reducer/features/gallery/presentation/pages/bulk_history_detail_page.dart';
import 'package:reducer/features/gallery/data/models/history_item.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      
      // -- MAIN SHELL ROUTES --
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // Home Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Editor Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/single-editor',
                builder: (context, state) => const SingleImageScreen(),
              ),
            ],
          ),
          // History Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gallery',
                builder: (context, state) => const GalleryScreen(),
              ),
            ],
          ),
          // Premium Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/premium',
                builder: (context, state) => const PremiumScreen(),
              ),
            ],
          ),
          // Profile Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // -- OTHER STANDALONE ROUTES --
      GoRoute(
        path: '/bulk-editor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BulkImageScreen(),
      ),
      GoRoute(
        path: '/bulk-history-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final item = state.extra as HistoryItem?;
          if (item == null) {
            return const Scaffold(body: Center(child: Text('History item missing')));
          }
          return BulkHistoryDetailScreen(item: item);
        },
      ),
      GoRoute(
        path: '/exif-eraser',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExifEraserScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LoginScreen(redirectTo: state.uri.queryParameters['redirect']),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RegisterScreen(redirectTo: state.uri.queryParameters['redirect']),
      ),
    ],
  );
});
