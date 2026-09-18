import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/design_system/providers/badge_provider.dart';
import 'package:otune/features/settings/application/settings_notifier.dart';
import 'package:otune/features/settings/presentation/widgets/theme_preference_tile.dart';

class SettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePreference = ref
        .watch(settingsProvider)
        .settings
        .themePreference;
    final badgeDuration = ref.watch(settingsProvider).settings.badgeDuration;

    return Scaffold(
      body: ListView(
        children: [
          ThemePreferenceTile(
            preference: themePreference,
            onChanged: ref.read(settingsProvider.notifier).updateTheme,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Duración de badges'),
            subtitle: Text('${badgeDuration.inSeconds} segundos'),
            trailing: DropdownButton<int>(
              value: badgeDuration.inSeconds,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateBadgeDuration(Duration(seconds: value));
                  ref
                      .read(badgeProvider.notifier)
                      .show(
                        message:
                            'Duración de badge actualizada a $value segundos',
                        type: BadgeType.success,
                      );
                }
              },
              items: [1, 2, 3, 5, 10]
                  .map(
                    (seconds) => DropdownMenuItem(
                      value: seconds,
                      child: Text('$seconds segundos'),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Información'),
            subtitle: const Text('Versión 0.5.0-alpha.1+22'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Otune',
                applicationVersion: '0.5.0-alpha.1+22',
                applicationIcon: Image.asset(
                  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
                  width: 48,
                  height: 48,
                ),
                applicationLegalese: '© 2026 Otune Team',
                children: [
                  const Text('By Oyhs-Co'),
                  const Text(
                    'Otune es un reproductor musical multiplataforma, '
                    'offline-first y extensible.',
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
