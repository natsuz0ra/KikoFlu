import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/utils/snackbar_util.dart';
import 'package:kikoeru_flutter/src/widgets/liquid_glass_layout.dart';

Widget _testApp(SnackBar snackBar) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () => SnackBarUtil.showFromSnackBar(
              context,
              snackBar,
            ),
            child: const Text('show'),
          );
        },
      ),
    ),
  );
}

void main() {
  group('SnackBarUtil.showFromSnackBar', () {
    testWidgets('converts red text snackbar to unified error style',
        (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SnackBar(
            content: Text('failed'),
            backgroundColor: Colors.red,
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.text('failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('extracts text from row content', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info),
                Expanded(child: Text('row message')),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.text('row message'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('falls back to original snackbar when text cannot be extracted',
        (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SnackBar(
            content: Icon(Icons.circle),
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.byIcon(Icons.circle), findsOneWidget);
    });

    testWidgets('moves a floating snackbar close above the measured dock',
        (tester) async {
      final dockExtent = ValueNotifier<double>(96);
      final action = SnackBarAction(label: 'undo', onPressed: () {});
      const duration = Duration(seconds: 7);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassDockScope(
              notifier: dockExtent,
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => SnackBarUtil.showFromSnackBar(
                    context,
                    SnackBar(
                      content: const Icon(Icons.circle),
                      action: action,
                      duration: duration,
                    ),
                  ),
                  child: const Text('show dock'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('show dock'));
      await tester.pump();

      final shown = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(shown.action, same(action));
      expect(shown.duration, duration);
      expect(shown.behavior, SnackBarBehavior.floating);
      expect((shown.margin! as EdgeInsets).bottom, 104);
    });

    testWidgets('converts fixed width into centered margins above the dock',
        (tester) async {
      final dockExtent = ValueNotifier<double>(96);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassDockScope(
              notifier: dockExtent,
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => SnackBarUtil.showFromSnackBar(
                    context,
                    const SnackBar(
                      content: Icon(Icons.circle),
                      width: 200,
                    ),
                  ),
                  child: const Text('show fixed width'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('show fixed width'));
      await tester.pump();

      final shown = tester.widget<SnackBar>(find.byType(SnackBar));
      final margin = shown.margin! as EdgeInsets;
      expect(shown.width, isNull);
      expect(margin.left, margin.right);
      expect(margin.bottom, 104);
    });

    testWidgets('supports a tighter page-specific dock gap', (tester) async {
      final dockExtent = ValueNotifier<double>(96);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassDockScope(
              notifier: dockExtent,
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => SnackBarUtil.showFromSnackBar(
                    context,
                    const SnackBar(
                      content: Text('cache cleared'),
                      backgroundColor: Colors.green,
                    ),
                    dockGap: 2,
                  ),
                  child: const Text('show tight gap'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('show tight gap'));
      await tester.pump();

      final shown = tester.widget<SnackBar>(find.byType(SnackBar));
      expect((shown.margin! as EdgeInsets).bottom, 98);
    });

  });
}
