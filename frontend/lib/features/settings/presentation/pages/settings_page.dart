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
        ],
      ),
    );
  }
}
