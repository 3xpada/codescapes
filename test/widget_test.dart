// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:codescapes/main.dart';

void main() {
  testWidgets('CodeScape home screen opens the play menu', (WidgetTester tester) async {
    await tester.pumpWidget(const CodeScapeApp());

    expect(find.text('C O D E'), findsOneWidget);
    expect(find.text('S C A P E S'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);

    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your game mode!'), findsOneWidget);
  });
}
