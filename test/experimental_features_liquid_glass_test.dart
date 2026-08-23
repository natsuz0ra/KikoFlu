import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/screens/experimental_features_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: ExperimentalFeaturesScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      LiquidGlassTopBarNotifier.preferenceKey: false,
      LiquidGlassNavigationNotifier.preferenceKey: true,
    });
  });

  testWidgets('shows independent top and bottom native glass switches', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_testApp(container));
    await tester.pumpAndSettle();

    expect(find.text('Top Bar Liquid Glass'), findsOneWidget);
    expect(find.text('Bottom Bar Liquid Glass'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(2));
    expect(find.byType(Slider), findsNothing);

    final switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .toList();
    expect(switches[0].value, isFalse);
    expect(switches[1].value, isTrue);

    await tester.tap(find.text('Top Bar Liquid Glass'));
    await tester.pumpAndSettle();
    expect(container.read(liquidGlassTopBarProvider), isTrue);
    expect(container.read(liquidGlassNavigationProvider), isTrue);

    await tester.tap(find.text('Bottom Bar Liquid Glass'));
    await tester.pumpAndSettle();
    expect(container.read(liquidGlassTopBarProvider), isTrue);
    expect(container.read(liquidGlassNavigationProvider), isFalse);
    expect(tester.takeException(), isNull);
  });
}
