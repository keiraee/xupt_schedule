import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupt_schedule_app/core/constants.dart';
import 'package:xupt_schedule_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLogin(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefsDisclaimerAcked: true,
    });
    await tester.pumpWidget(const XuptScheduleApp(startOnSchedule: false));
    await tester.pump();
  }

  testWidgets('boots to login shell without session', (tester) async {
    await pumpLogin(tester);
    expect(find.text('西邮课表'), findsOneWidget);
  });

  testWidgets('login does not scroll until keyboard opens', (tester) async {
    addTearDown(tester.view.reset);
    await pumpLogin(tester);
    expect(
      tester.widget<CustomScrollView>(find.byType(CustomScrollView)).physics,
      isA<NeverScrollableScrollPhysics>(),
    );

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();
    expect(
      tester.widget<CustomScrollView>(find.byType(CustomScrollView)).physics,
      isA<ClampingScrollPhysics>(),
    );
  });

  testWidgets('login form is vertically centered', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpLogin(tester);
    final title = tester.getCenter(find.text('西邮课表'));
    expect(title.dy, greaterThan(220));
    expect(title.dy, lessThan(420));
  });

  testWidgets('opening keyboard keeps username focus', (tester) async {
    addTearDown(tester.view.reset);
    await pumpLogin(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    expect(_editableFocused(tester), isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();
    expect(_editableFocused(tester), isTrue);
  });

  testWidgets('tapping username keeps focus', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_editableFocused(tester), isTrue);
  });

  testWidgets('tapping blank area unfocuses login field', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    expect(_editableFocused(tester), isTrue);

    await tester.tap(find.text('西邮课表'));
    await tester.pump();
    expect(_editableFocused(tester), isFalse);
  });
}

bool _editableFocused(WidgetTester tester) {
  return tester
      .widgetList<EditableText>(find.byType(EditableText))
      .any((widget) => widget.focusNode.hasFocus);
}
