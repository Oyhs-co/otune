import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Página de carga inicial (Splash Screen).
class SplashPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_navigateToHome());
  }

  Future<void> _navigateToHome() async {
    // Tiempo de espera para mostrar el splash screen
    await Future<void>.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: theme.colorScheme.surface,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo (Icono representativo mientras no haya assets)
            Icon(
              Icons.music_note_rounded,
              size: 100,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            // Nombre de la App
            Text(
              'Otune',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // Firma
            Text(
              'By Oyhs-Co',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            // Indicador de carga
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
