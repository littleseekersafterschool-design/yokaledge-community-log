import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:staff_log/main.dart';
import 'package:staff_log/providers/app_provider.dart';

void main() {
  testWidgets('App starts and shows loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const StaffLogApp(),
      ),
    );
    expect(find.text('Staff Log'), findsOneWidget);
  });
}
