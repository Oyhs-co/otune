import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/settings/application/settings_notifier.dart';
import 'package:otune/features/settings/domain/entities/app_settings.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final themePref = state.settings.themePreference;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Tema Visual'),
            subtitle: Text(_getThemeText(themePref)),
            trailing: DropdownButton<ThemePreference>(
              value: themePref,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateTheme(value);
                }
              },
              items: ThemePreference.values.map((pref) {
                return DropdownMenuItem(
                  value: pref,
                  child: Text(_getThemeText(pref)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeText(ThemePreference pref) {
    switch (pref) {
      case ThemePreference.system: return 'Sistema';
      case ThemePreference.light: return 'Claro';
      case ThemePreference.dark: return 'Oscuro';
    }
  }
}
