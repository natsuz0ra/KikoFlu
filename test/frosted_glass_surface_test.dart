import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/frosted_glass_surface.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

void main() {
  testWidgets('frosted surface clips a single bounded backdrop filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 60,
            child: FrostedGlassSurface(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(FrostedGlassSurface), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
    final decorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>();
    expect(decorations.any((decoration) => decoration.border != null), isTrue);
    expect(
      decorations.any(
        (decoration) => decoration.boxShadow?.isNotEmpty ?? false,
      ),
      isTrue,
    );
    expect(
      decorations.any((decoration) => decoration.gradient is LinearGradient),
      isTrue,
    );
  });

  testWidgets('liquid glass fallback can reuse a custom surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          height: 60,
          child: LiquidGlassContainer(
            fallbackSurfaceBuilder: (context) => const ColoredBox(
              key: ValueKey('custom-fallback-surface'),
              color: Colors.transparent,
            ),
            child: const Text('content'),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('custom-fallback-surface')),
      findsOneWidget,
    );
    expect(find.text('content'), findsOneWidget);
  });
}
