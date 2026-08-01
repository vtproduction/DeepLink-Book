import 'package:deep_link_book/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows the initial home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.text('Deeplink Manager'), findsOneWidget);
    expect(find.text('Deeplink Manager is ready.'), findsOneWidget);
  });
}
