import 'package:flutter/material.dart';
import 'package:otune/features/settings/domain/entities/app_settings.dart';

/// Control visual para seleccionar la preferencia de tema.
class ThemePreferenceTile extends StatelessWidget {
  const new({
    required this.preference,
    required this.onChanged,
    super.key,
  });

  final ThemePreference preference;
  final ValueChanged<ThemePreference> onChanged;

  String _getThemeText(ThemePreference value) {
    switch (value) {
      case ThemePreference.system:
        return 'Sistema';
      case ThemePreference.light:
        return 'Claro';
      case ThemePreference.dark:
        return 'Oscuro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Tema Visual'),
      subtitle: Text(_getThemeText(preference)),
      trailing: DropdownButton<ThemePreference>(
        value: preference,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        items: ThemePreference.values.map((value) {
          return DropdownMenuItem(
            value: value,
            child: Text(_getThemeText(value)),
          );
        }).toList(),
      ),
    );
  }
}
