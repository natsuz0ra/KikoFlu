import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/platform/harmony_native_overlay.dart';

void main() {
  testWidgets('preserves the ordinary overlay path off HarmonyOS', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    var calls = 0;
    final result = await showWithNativeShellSuppressed<int>(context, () async {
      calls++;
      return 7;
    });

    expect(calls, 1);
    expect(result, 7);
  });
}
