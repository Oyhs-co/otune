import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otune/core/design_system/providers/badge_provider.dart';
import 'package:otune/core/permissions/permission_service.dart';
import 'package:otune/features/library/application/library_view_provider.dart';
import 'package:otune/features/library/application/state/library_scan_state.dart';
import 'package:otune/features/library/presentation/widgets/library_app_bar_actions.dart';
import 'package:otune/features/playback/presentation/widgets/mini_player.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  Future<void> _handleScanFolder(BuildContext context, WidgetRef ref) async {
    final hasPermission = await PermissionService().requestMediaPermissions();

    if (!hasPermission) {
      if (!context.mounted) return;
      ref
          .read(badgeProvider.notifier)
          .show(
            message:
                'Se requiere permiso de almacenamiento para escanear música',
            type: BadgeType.error,
          );
      return;
    }

    final selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory == null || !context.mounted) return;

    await ref
        .read(libraryScanProvider.notifier)
        .scanDirectory(selectedDirectory);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;
    final isLibraryPage = navigationShell.currentIndex == 0;
    final scanState = ref.watch(libraryScanProvider);
    final badges = ref.watch(badgeProvider);

    return Scaffold(
      appBar: isWideScreen
          ? null
          : AppBar(
              title: const Text('Otune'),
              centerTitle: false,
              actions: isLibraryPage
                  ? [
                      LibraryAppBarActions(
                        isScanning: scanState.isScanning,
                        onViewModeChanged: (mode) =>
                            ref.read(libraryViewModeProvider.notifier).mode =
                                mode,
                        onScanFolder: () => _handleScanFolder(context, ref),
                      ),
                    ]
                  : null,
            ),
      body: Stack(
        children: [
          Row(
            children: [
              if (isWideScreen)
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: navigationShell.goBranch,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
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
                child: Column(
                  children: [
                    Expanded(child: navigationShell),
                    const SafeArea(top: false, child: MiniPlayer()),
                  ],
                ),
              ),
            ],
          ),
          if (badges.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _BadgeStack(badges: badges),
                ),
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

class _BadgeStack extends ConsumerWidget {
  const _BadgeStack({required this.badges});

  final List<BadgeItem> badges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: badges
          .map(
            (badge) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: StateBadge(
                key: ValueKey(badge.id),
                message: badge.message,
                type: badge.type,
                backgroundColor: badge.backgroundColor,
                textColor: badge.textColor,
                duration: badge.duration,
                onDismissed: () {
                  ref.read(badgeProvider.notifier).dismiss(badge.id);
                },
                actionLabel: badge.actionLabel,
                onActionPressed: badge.onActionPressed,
              ),
            ),
          )
          .toList(),
    );
  }
}
