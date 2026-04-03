import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showtickets/app.dart';
import 'package:showtickets/providers/providers.dart';

void main() {
  testWidgets('app loads home shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ShowTicketsApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsOneWidget);
  });
}
