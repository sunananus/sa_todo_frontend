import 'package:flutter_test/flutter_test.dart';
import 'package:sa_todo/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // Basic smoke test - app should render without errors
  });
}
