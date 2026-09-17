import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          ThemePreferenceTile(
            preference: themePreference,
            onChanged: ref.read(settingsProvider.notifier).updateTheme,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Información'),
            subtitle: const Text('Versión 0.4.0-alpha.2+20'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Otune',
                applicationVersion: '0.4.0-alpha.2+20',
                applicationIcon: Image.asset(
                  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
                  width: 48,
                  height: 48,
                ),
                applicationLegalese: '© 2026 Otune Team',
                children: [
                  const Text(
                    'Otune es un reproductor musical multiplataforma, '
                    'offline-first y extensible.',
                  ),
                  const SizedBox(height: 8),
                  const Text('By Oyhs-Co'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
