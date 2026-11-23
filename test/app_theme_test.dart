import 'package:codescapes/app_state.dart';
import 'package:codescapes/main.dart';
import 'package:codescapes/theme/app_colors.dart';
import 'package:codescapes/widgets/app_background.dart';
import 'package:codescapes/widgets/code_bot_mascot.dart';
import 'package:codescapes/widgets/world_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SharedPreferences.setMockInitialValues({
      'codescapes.audio.music': false,
      'codescapes.audio.effects': false,
      'player_username': 'TestPlayer',
    });
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => appTheme.value = AppThemeOption.cyber);

    await tester.pumpWidget(const CodescapeApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final logo = find.byKey(const ValueKey('idle-home-logo'));
    expect(logo, findsOneWidget);
    final initialLogoY = tester
        .widget<Transform>(logo)
        .transform
        .getTranslation()
        .y;
    await tester.pump(const Duration(milliseconds: 500));
    final floatingLogoY = tester
        .widget<Transform>(logo)
        .transform
        .getTranslation()
        .y;
    expect(floatingLogoY, isNot(closeTo(initialLogoY, 0.1)));
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('ACHIEVEMENTS'), findsOneWidget);
    expect(find.text('DAILY PUZZLE'), findsNothing);
    expectFullPageBackground(tester, AppColors.cyber.bgTop);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('SETTINGS'));
    await tester.tap(find.text('SETTINGS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(find.text('Daylight'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('SETTINGS'))).brightness,
      Brightness.light,
    );
    expectFullPageBackground(tester, AppColors.daylight.bgTop);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.ensureVisible(find.text('PLAY'));
    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Python Valley'), findsOneWidget);
    expect(find.text('Java Foundry'), findsOneWidget);
    expect(find.text('C# Circuit'), findsOneWidget);
    expect(find.text('C Workshop'), findsOneWidget);
    expect(find.text('GRID MAZE'), findsNothing);
    await tester.tap(find.text('Python Valley'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('PYTHON'), findsOneWidget);
    expect(find.byType(WorldBackground), findsOneWidget);
    expect(find.text("WHAT YOU'RE CODING"), findsOneWidget);
    expect(
      find.text('Write a print statement that greets the world.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Byte, your coding companion'), findsOneWidget);
    expect(find.byType(CodeBotMascot), findsOneWidget);
    expect(find.text('10 COINS'), findsOneWidget);
    expectFullPageBackground(tester, AppColors.daylight.bgTop);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byTooltip('Buy a hint for 10 coins'));
    await tester.tap(find.byTooltip('Buy a hint for 10 coins'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text("BYTE'S HINTS"), findsNothing);
    expect(
      find.textContaining("Which word comes after 'Hello, '?"),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.textContaining("Which word comes after 'Hello, '?"),
      findsOneWidget,
    );
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .hideCurrentSnackBar();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byTooltip('Byte, your coding companion'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'World');
    await tester.ensureVisible(find.text('RUN CODE'));
    await tester.tap(find.text('RUN CODE'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('SUCCESS'), findsOneWidget);
    final successDialogRect = tester.getRect(find.byType(Dialog));
    expect(successDialogRect.center.dx, closeTo(160, 1));
    expect(successDialogRect.center.dy, closeTo(320, 1));
    expect(find.byType(CodeBotMascot), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('NEXT LEVEL'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('LEVEL 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('RUN CODE'));
    await tester.tap(find.text('RUN CODE'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('INCOMPLETE BLANKS'), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
    await tester.tap(find.text('TRY AGAIN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Java Foundry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('JAVA'), findsOneWidget);
    expect(find.text('FIRST OUTPUT'), findsOneWidget);
    expect(find.textContaining('System.out.println'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.ensureVisible(find.text('C# Circuit'));
    await tester.tap(find.text('C# Circuit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('C#'), findsOneWidget);
    expect(find.text('FIRST OUTPUT'), findsOneWidget);
    expect(find.textContaining('Console.WriteLine'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.ensureVisible(find.text('C Workshop'));
    await tester.tap(find.text('C Workshop'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('C'), findsOneWidget);
    expect(find.text('FIRST OUTPUT'), findsOneWidget);
    expect(find.textContaining('printf'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
