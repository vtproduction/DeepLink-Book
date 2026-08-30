import 'package:deep_link_book/features/deeplinks/builder/deeplink_builder_editor.dart';
import 'package:deep_link_book/features/deeplinks/builder/deeplink_query_parameter.dart';
import 'package:deep_link_book/features/deeplinks/builder/parsed_deeplink.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'disabled parameters stay visible but are excluded from preview',
    (tester) async {
      var latestUrl = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeeplinkBuilderEditor(
                parsedDeeplink: ParsedDeeplink(
                  scheme: 'deeplinktest',
                  host: 'transfer',
                  path: '',
                  queryParameters: [
                    DeeplinkQueryParameter(key: 'amount', value: '1000'),
                    DeeplinkQueryParameter(key: 'proxy', value: '0899999'),
                  ],
                ),
                parsedDeeplinkVersion: 0,
                rawCannotSyncToBuilder: false,
                onBuilderChanged: (url, parsedDeeplink) {
                  latestUrl = url;
                },
                enabled: true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();

      expect(find.text('proxy'), findsOneWidget);
      expect(latestUrl, 'deeplinktest://transfer?amount=1000#');
    },
  );

  testWidgets('boolean parameters use a true or false selector', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeeplinkBuilderEditor(
            parsedDeeplink: ParsedDeeplink(
              scheme: 'deeplinktest',
              host: 'transfer',
              path: '',
              queryParameters: [
                DeeplinkQueryParameter(
                  key: 'editable',
                  value: 'not boolean',
                  type: DeeplinkParameterType.boolean,
                ),
              ],
            ),
            parsedDeeplinkVersion: 0,
            rawCannotSyncToBuilder: false,
            onBuilderChanged: (_, _) {},
            enabled: true,
          ),
        ),
      ),
    );

    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'true'),
      findsOneWidget,
    );
    expect(find.text('not boolean'), findsNothing);
  });

  testWidgets('changing type to boolean normalizes the current value', (
    tester,
  ) async {
    var latestUrl = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeeplinkBuilderEditor(
            parsedDeeplink: ParsedDeeplink(
              scheme: 'deeplinktest',
              host: 'transfer',
              path: '',
              queryParameters: [
                DeeplinkQueryParameter(key: 'editable', value: 'abc'),
              ],
            ),
            parsedDeeplinkVersion: 0,
            rawCannotSyncToBuilder: false,
            onBuilderChanged: (url, parsedDeeplink) {
              latestUrl = url;
            },
            enabled: true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('String'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boolean').last);
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'true'),
      findsOneWidget,
    );
    expect(find.text('abc'), findsNothing);
    expect(latestUrl, 'deeplinktest://transfer?editable=true#');
  });
}
