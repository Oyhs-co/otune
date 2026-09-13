import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/app/router/app_router.dart';
import 'package:otune/app/theme/app_theme.dart';

/// Widget raíz de la aplicación Otune.
class OtuneApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: 'Otune',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(lightDynamic?.primary),
          darkTheme: AppTheme.dark(darkDynamic?.primary),
          routerConfig: router,
        );
      },
    );
  }
}
