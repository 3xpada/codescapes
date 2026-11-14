import 'package:codescapes/app_state.dart';
import 'package:codescapes/main.dart';
import 'package:codescapes/theme/app_colors.dart';
import 'package:codescapes/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void expectFullPageBackground(WidgetTester tester, Color color) {
  final background = find.byType(AppBackground).first;
  final backgroundStack = find
      .descendant(of: background, matching: find.byType(Stack))
      .first;

  expect(tester.getSize(backgroundStack), tester.getSize(background));
  expect(
    find.descendant(
      of: background,
      matching: find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == color,
      ),
    ),
    findsOneWidget,
  );
}

void main() {
  testWidgets('theme choice is applied across compact app screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => appTheme.value = AppThemeOption.cyber);

    await tester.pumpWidget(const CodescapeApp());
    await tester.pumpAndSettle();
    expect(find.text('PLAY'), findsOneWidget);
    expectFullPageBackground(tester, AppColors.cyber.bgTop);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daylight'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('SETTINGS'))).brightness,
      Brightness.light,
    );
    expectFullPageBackground(tester, AppColors.daylight.bgTop);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Python basics'), findsOneWidget);
    await tester.tap(find.text('FILL THE BLANKS'));
    await tester.pumpAndSettle();

    expect(find.text('PYTHON'), findsOneWidget);
    expect(find.text("WHAT YOU'RE CODING"), findsOneWidget);
    expect(
      find.text('Write a print statement that greets the world.'),
      findsOneWidget,
    );
    expect(find.text('10 COINS'), findsOneWidget);
    expectFullPageBackground(tester, AppColors.daylight.bgTop);
    expect(tester.takeException(), isNull);
  });
}
