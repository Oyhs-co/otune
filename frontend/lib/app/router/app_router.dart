import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otune/features/library/presentation/pages/library_page.dart';
import 'package:otune/features/playback/presentation/pages/home_page.dart';
import 'package:otune/features/settings/presentation/pages/settings_page.dart';

/// Proveedor del enrutador principal de la aplicación.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/library',
        name: 'library',
        builder: (context, state) => const LibraryPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
