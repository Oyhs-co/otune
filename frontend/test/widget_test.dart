import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/app/app.dart';

void main() {
  testWidgets('OtuneApp renders home page smoke test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OtuneApp()));

    expect(find.text('Otune'), findsWidgets);
    expect(find.text('Bienvenido a Otune'), findsOneWidget);
  });
}
