import 'package:codescapes/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first launch registers a username and profile can edit it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CodescapeApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('CREATE YOUR PROFILE'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump();

    expect(find.text('PLAY'), findsOneWidget);
    await tester.ensureVisible(find.text('PLAYER PROFILE'));
    await tester.tap(find.text('PLAYER PROFILE'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Ada').last, findsOneWidget);
    expect(find.text('PUZZLES COMPLETED'), findsOneWidget);

    await tester.tap(find.text('EDIT USERNAME'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      'Grace Hopper',
    );
    await tester.tap(find.text('SAVE'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Grace Hopper'), findsOneWidget);
    await tester.tap(find.text('VIEW ACHIEVEMENTS'));
    await tester.pump();
    await tester.pump();
    expect(find.text('ACHIEVEMENTS').last, findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('0 / 1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
