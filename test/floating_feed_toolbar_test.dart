import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/widgets/floating_feed_toolbar.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testApp(Widget child, {ProviderContainer? container}) {
  final app = MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 390, child: child)),
    ),
  );
  return container == null
      ? ProviderScope(child: app)
      : UncontrolledProviderScope(container: container, child: app);
}

Widget _wideTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 700, child: child)),
      ),
    ),
  );
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      LiquidGlassNavigationNotifier.preferenceKey: false,
    }),
  );

  testWidgets('renders two capsules and keeps their actions interactive', (
    tester,
  ) async {
    var selectedMode = '';
    var toolTaps = 0;

    await tester.pumpWidget(
      _testApp(
        FloatingFeedToolbar(
          modeActions: [
            FloatingFeedModeAction(
              icon: Icons.grid_view,
              label: 'All',
              isSelected: true,
              onPressed: () => selectedMode = 'all',
            ),
            FloatingFeedModeAction(
              icon: Icons.local_fire_department,
              label: 'Popular',
              isSelected: false,
              onPressed: () => selectedMode = 'popular',
            ),
          ],
          toolActions: [
            FloatingFeedToolAction(
              icon: Icons.closed_caption,
              tooltip: 'Subtitles',
              isSelected: true,
              onPressed: () => toolTaps++,
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('feed-mode-capsule')), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-tool-capsule')), findsOneWidget);
    expect(tester.getSize(find.byType(FloatingFeedToolbar)).height, 48);
    final surfaceMaterial = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('feed-mode-capsule')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(
      surfaceMaterial.color?.a,
      closeTo(FloatingToolbarSurface.backgroundOpacity, 0.001),
    );

    await tester.tap(find.text('Popular'));
    await tester.tap(find.byTooltip('Subtitles'));
    expect(selectedMode, 'popular');
    expect(toolTaps, 1);
  });

  testWidgets('uses real liquid glass when the navigation style is enabled', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(liquidGlassNavigationProvider.notifier)
        .setEnabled(true);

    await tester.pumpWidget(
      _testApp(
        const FloatingToolbarSurface(child: SizedBox(width: 80, height: 40)),
        container: container,
      ),
    );

    expect(find.byType(LiquidGlassContainer), findsOneWidget);
    final material = tester.widget<Material>(find.byType(Material).last);
    expect(material.type, MaterialType.transparency);
  });

  testWidgets('fallback liquid glass keeps page content visible', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(liquidGlassNavigationProvider.notifier)
        .setEnabled(true);
    await container
        .read(fallbackGlassTransparencyProvider.notifier)
        .setTransparency(0.9);

    await tester.pumpWidget(
      _testApp(
        const FloatingToolbarSurface(child: SizedBox(width: 80, height: 40)),
        container: container,
      ),
    );

    final glass = find.byType(LiquidGlassContainer);
    expect(tester.widget<LiquidGlassContainer>(glass).fallbackIntensity, 0.9);
    final fallbackDecoration = tester
        .widgetList<DecoratedBox>(
          find.descendant(of: glass, matching: find.byType(DecoratedBox)),
        )
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((decoration) => decoration.color != null);
    expect(fallbackDecoration.color!.a, lessThan(0.5));
    expect(
      find.descendant(of: glass, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('progressive top treatment uses one bounded blur pass', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 44)),
          child: ProgressiveTopBlur(height: 96),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(tester.getSize(find.byType(ProgressiveTopBlur)).height, 96);
  });

  testWidgets('top treatment is omitted without a status bar inset', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const ProgressiveTopBlur(height: 96)));

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('secondary toolbar follows the primary toolbar position', (
    tester,
  ) async {
    final primaryVisible = ValueNotifier(true);
    addTearDown(primaryVisible.dispose);

    await tester.pumpWidget(
      _testApp(
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              FloatingToolbarPositionFollower(
                primaryToolbarVisible: primaryVisible,
                visibleTop: 100,
                hiddenTop: 44,
                left: 0,
                right: 0,
                child: const SizedBox(
                  key: ValueKey('secondary-toolbar'),
                  height: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final visibleTop = tester
        .getTopLeft(find.byKey(const ValueKey('secondary-toolbar')))
        .dy;
    expect(find.byType(OverlayPortal), findsOneWidget);
    expect(find.byType(CompositedTransformFollower), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('secondary-toolbar'))).width,
      390,
    );
    primaryVisible.value = false;
    await tester.pumpAndSettle();
    final hiddenTop = tester
        .getTopLeft(find.byKey(const ValueKey('secondary-toolbar')))
        .dy;

    expect(visibleTop - hiddenTop, 56);
  });

  testWidgets('mode capsule hugs its content and leaves tools at the edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wideTestApp(
        FloatingFeedToolbar(
          modeActions: [
            FloatingFeedModeAction(
              icon: Icons.grid_view,
              label: 'All',
              isSelected: true,
              onPressed: () {},
            ),
          ],
          toolActions: [
            FloatingFeedToolAction(
              icon: Icons.sort,
              tooltip: 'Sort',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    final mode = tester.getRect(
      find.byKey(const ValueKey('feed-mode-capsule')),
    );
    final tools = tester.getRect(
      find.byKey(const ValueKey('feed-tool-capsule')),
    );
    expect(mode.width, lessThan(160));
    expect(tools.right, closeTo(750, 1));
  });

  testWidgets('shows every mode when the complete row fits', (tester) async {
    await tester.pumpWidget(
      _wideTestApp(
        FloatingFeedToolbar(
          modeActions: [
            for (final label in ['全部', '想听', '在听', '听过', '重听', '搁置'])
              FloatingFeedModeAction(
                icon: Icons.filter_alt,
                label: label,
                isSelected: label == '全部',
                onPressed: () {},
              ),
          ],
          toolActions: [
            for (var index = 0; index < 3; index++)
              FloatingFeedToolAction(
                icon: Icons.tune,
                tooltip: 'Tool $index',
                onPressed: () {},
              ),
          ],
        ),
      ),
    );

    final mode = tester.getRect(
      find.byKey(const ValueKey('feed-mode-capsule')),
    );
    expect(mode.width, greaterThan(420));
    expect(find.text('搁置'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-mode-dropdown')), findsNothing);
  });

  testWidgets('uses a mode dropdown when the complete row does not fit', (
    tester,
  ) async {
    var selectedMode = -1;
    await tester.pumpWidget(
      _testApp(
        FloatingFeedToolbar(
          modeActions: [
            for (var index = 0; index < 8; index++)
              FloatingFeedModeAction(
                icon: Icons.filter_alt,
                label: 'Filter option $index',
                isSelected: index == 0,
                onPressed: () => selectedMode = index,
              ),
          ],
          toolActions: [
            FloatingFeedToolAction(
              icon: Icons.sort,
              tooltip: 'Sort',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('feed-mode-dropdown')), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    final dropdown = tester.widget<PopupMenuButton<int>>(
      find.descendant(
        of: find.byKey(const ValueKey('feed-mode-dropdown')),
        matching: find.byType(PopupMenuButton<int>),
      ),
    );
    expect(dropdown.borderRadius, BorderRadius.circular(20));
    await tester.tap(find.byKey(const ValueKey('feed-mode-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filter option 1'));
    await tester.pumpAndSettle();
    expect(selectedMode, 1);
  });

  testWidgets('fills a narrow mode capsule without horizontal scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        FloatingFeedToolbar(
          collapseModesWhenNeeded: false,
          modeActions: [
            for (final label in ['全部', '热门', '推荐'])
              FloatingFeedModeAction(
                icon: Icons.filter_alt,
                label: label,
                isSelected: label == '全部',
                onPressed: () {},
              ),
          ],
          toolActions: [
            for (var index = 0; index < 4; index++)
              FloatingFeedToolAction(
                icon: Icons.tune,
                tooltip: 'Tool $index',
                onPressed: () {},
              ),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('feed-mode-dropdown')), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('热门'), findsOneWidget);
    expect(find.text('推荐'), findsOneWidget);

    final capsule = tester.getRect(
      find.byKey(const ValueKey('feed-mode-capsule')),
    );
    for (final label in ['全部', '热门', '推荐']) {
      final labelRect = tester.getRect(find.text(label));
      expect(labelRect.left, greaterThanOrEqualTo(capsule.left));
      expect(labelRect.right, lessThanOrEqualTo(capsule.right));
    }
  });

  testWidgets('slides the filled mode indicator between homepage modes', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const _SelectableModeToolbar()));

    final indicator = find.byKey(const ValueKey('feed-mode-indicator'));
    final initialLeft = tester.getTopLeft(indicator).dx;

    await tester.tap(find.text('推荐'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final middleLeft = tester.getTopLeft(indicator).dx;

    await tester.pumpAndSettle();
    final finalLeft = tester.getTopLeft(indicator).dx;

    expect(middleLeft, greaterThan(initialLeft));
    expect(middleLeft, lessThan(finalLeft));
    expect(finalLeft - initialLeft, greaterThan(100));
  });
}

class _SelectableModeToolbar extends StatefulWidget {
  const _SelectableModeToolbar();

  @override
  State<_SelectableModeToolbar> createState() => _SelectableModeToolbarState();
}

class _SelectableModeToolbarState extends State<_SelectableModeToolbar> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const labels = ['全部', '热门', '推荐'];
    return FloatingFeedToolbar(
      collapseModesWhenNeeded: false,
      modeActions: [
        for (var index = 0; index < labels.length; index++)
          FloatingFeedModeAction(
            icon: Icons.filter_alt,
            label: labels[index],
            isSelected: selectedIndex == index,
            onPressed: () => setState(() => selectedIndex = index),
          ),
      ],
      toolActions: [
        for (var index = 0; index < 4; index++)
          FloatingFeedToolAction(
            icon: Icons.tune,
            tooltip: 'Tool $index',
            onPressed: () {},
          ),
      ],
    );
  }
}
