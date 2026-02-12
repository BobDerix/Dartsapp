import 'package:flutter_test/flutter_test.dart';
import 'package:dartsapp/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DartsApp());
    await tester.pumpAndSettle();

    expect(find.text('PRO EDITION'), findsOneWidget);
    expect(find.text('START MATCH'), findsOneWidget);
  });
}
