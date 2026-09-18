import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otune/features/playback/presentation/widgets/mini_player.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_filled),
                  label: Text('Inicio'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.library_music),
                  label: Text('Biblioteca'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Ajustes'),
                ),
              ],
            ),
          Expanded(
            child: Stack(
              children: [
                navigationShell,
                Positioned(
                  bottom: isWideScreen ? 0 : 80,
                  left: 0,
                  right: 0,
                  child: const MiniPlayer(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isWideScreen
          ? BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: navigationShell.goBranch,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music),
                  label: 'Biblioteca',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Ajustes',
                ),
              ],
            )
          : null,
    );
  }
}
