import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('start tag renders a minimal placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Placeholder());

    expect(find.byType(Placeholder), findsOneWidget);
  });
}
