import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wms/main.dart';

void main() {
  testWidgets('WMS app shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WmsApp()));
    expect(find.text('WMS App Skeleton'), findsOneWidget);
  });
}
