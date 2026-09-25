import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/library/application/state/library_scan_state.dart';
import 'package:otune/features/library/presentation/widgets/library_app_bar_actions.dart';
import 'package:otune/features/library/presentation/widgets/library_scan_banner.dart';

/// El banner sólo depende del estado de escaneo; no toca el repositorio.
/// Se reutiliza el provider real y se conduce el notificador directamente.
void main() {
  Future<void> pumpBanner(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: LibraryScanBanner())),
      ),
    );
  }

  testWidgets('hidden when no scan has run', (tester) async {
    await pumpBanner(tester);

    expect(find.text('Reintentar'), findsNothing);
    expect(find.byType(LibraryScanBanner), findsOneWidget);
  });

  testWidgets('shows retry button enabled when scan failed and stopped', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: LibraryScanBanner())),
      ),
    );

    container
        .read(libraryScanProvider.notifier)
        .debugSetStateForTest(
          const LibraryScanControllerState(
            scan: LibraryScanState(
              status: 'Error: carpeta inaccesible',
              lastScanPath: '/music',
            ),
          ),
        );
    await tester.pump();

    final button = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Reintentar'),
        matching: find.byType(TextButton),
      ),
    );
    expect(
      button.onPressed,
      isNotNull,
      reason: 'F-02: con el escaneo detenido el botón debe estar habilitado',
    );
  });

  testWidgets('shows cancel button while scanning', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: LibraryScanBanner())),
      ),
    );

    container
        .read(libraryScanProvider.notifier)
        .debugSetStateForTest(
          const LibraryScanControllerState(
            scan: LibraryScanState(isScanning: true, status: 'Escaneando...'),
          ),
        );
    await tester.pump();

    final button = tester.widget<ScanCancelButton>(
      find.byType(ScanCancelButton),
    );
    expect(button.onPressed, isNotNull);
  });
}
