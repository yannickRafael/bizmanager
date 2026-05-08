import 'package:flutter_test/flutter_test.dart';
import 'package:farma/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FarmaApp());
    expect(find.byType(FarmaApp), findsOneWidget);
  });
}
