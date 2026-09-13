import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupt_schedule_app/core/constants.dart';
import 'package:xupt_schedule_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots to login shell without session', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefsDisclaimerAcked: true,
    });
    await tester.pumpWidget(const XuptScheduleApp(startOnSchedule: false));
    await tester.pump();
    expect(find.text('西邮课表'), findsOneWidget);
  });
}
