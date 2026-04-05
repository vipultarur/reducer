import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
import 'package:reducer/features/splash/splash.dart';
import 'package:reducer/features/home/home.dart';
import 'package:reducer/features/editor/editor.dart';
import 'package:reducer/features/bulk/bulk.dart';
import 'package:reducer/features/premium/premium.dart';
import 'package:reducer/features/gallery/gallery.dart';
import 'package:reducer/features/exif/exif.dart';
import 'package:reducer/features/settings/settings.dart';

Widget _splash(BuildContext _, GoRouterState __) => const SplashScreen();
Widget _home(BuildContext _, GoRouterState __) => const HomeScreen();
Widget _single(BuildContext _, GoRouterState __) => const SingleImageScreen();
Widget _bulk(BuildContext _, GoRouterState __) => const BulkImageScreen();
Widget _premium(BuildContext _, GoRouterState __) => const PremiumScreen();
Widget _gallery(BuildContext _, GoRouterState __) => const GalleryScreen();
Widget _exif(BuildContext _, GoRouterState __) => const ExifEraserScreen();
Widget _settings(BuildContext _, GoRouterState __) => const SettingsScreen();
Widget _privacy(BuildContext _, GoRouterState __) => const PrivacyPolicyScreen();
Widget _bulkHistory(BuildContext _, GoRouterState state) => BulkHistoryDetailScreen(item: state.extra as HistoryItem);

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: _splash),
    GoRoute(path: '/', builder: _home),
    GoRoute(path: '/home', builder: _home),
    GoRoute(path: '/single-editor', builder: _single),
    GoRoute(path: '/bulk-editor', builder: _bulk),
    GoRoute(path: '/premium', builder: _premium),
    GoRoute(path: '/gallery', builder: _gallery),
    GoRoute(path: '/bulk-history-detail', builder: _bulkHistory),
    GoRoute(path: '/exif-eraser', builder: _exif),
    GoRoute(path: '/settings', builder: _settings),
    GoRoute(path: '/privacy-policy', builder: _privacy),
  ],
);
