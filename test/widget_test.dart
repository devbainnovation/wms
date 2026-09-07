import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wms/app.dart';
import 'package:wms/core/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WMS app shell renders UserPhoneLoginScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushNotificationInitProvider.overrideWith((ref) async {}),
          fcmTokenProvider.overrideWith((ref) async => null),
          appLaunchProvider.overrideWith(
            (ref) => const AppLaunchState.userPhoneLogin(),
          ),
        ],
        child: const WmsApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome To Di-WMS'), findsOneWidget);
    expect(find.text('Verify your identity via mobile number'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}
