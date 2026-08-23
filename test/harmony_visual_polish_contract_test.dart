import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'keeps native top treatment cheap and the My filter structurally equal',
    () {
      final source = File(
        'ohos/entry/src/main/ets/immersive/ImmersiveTopBar.ets',
      ).readAsStringSync();

      expect(source, contains('.linearGradient({'));
      expect(source, isNot(contains('.linearGradientBlur(')));
      expect(
        RegExp(r'\.width\(SECONDARY_FILTER_WIDTH\)').allMatches(source).length,
        2,
      );
      expect(source, contains('.bindMenu(this.secondaryMenu'));
    },
  );

  test('keeps refresh, MiniPlayer, keyboard and popup suppression bounded', () {
    final works = File('lib/src/screens/works_screen.dart').readAsStringSync();
    final my = File('lib/src/screens/my_screen.dart').readAsStringSync();
    final toolbar = File(
      'lib/src/widgets/floating_feed_toolbar.dart',
    ).readAsStringSync();
    final miniPlayer = File(
      'lib/src/widgets/mini_player.dart',
    ).readAsStringSync();
    final mainScreen = File(
      'lib/src/screens/main_screen.dart',
    ).readAsStringSync();
    final overlay = File(
      'lib/src/platform/harmony_native_overlay.dart',
    ).readAsStringSync();
    final search = File(
      'lib/src/screens/search_screen.dart',
    ).readAsStringSync();

    expect(
      works,
      allOf(
        contains('? FloatingToolbarLayout'),
        contains('.nativeRefreshIndicatorDisplacement'),
      ),
    );
    expect(
      toolbar,
      allOf(
        contains(
          'static const double nativeRefreshIndicatorDisplacement = 16;',
        ),
        contains('static const double toolbarStride ='),
        contains('static double contentTopAfterRows('),
      ),
    );
    expect(
      my,
      allOf(
        contains('rows: _tabSwitcherVisible.value ? 2 : 1'),
        contains('refreshIndicatorEdgeOffset: nativeTopActive'),
        contains('FloatingToolbarLayout.nativeRefreshIndicatorDisplacement'),
      ),
    );
    expect(miniPlayer, contains('fallbackIntensity: 0.86'));
    expect(mainScreen, contains('MediaQuery.viewInsetsOf(context).bottom > 0'));
    expect(mainScreen, contains('searchInputFocused.value'));
    expect(search, contains('onFocusChange: (focused)'));
    expect(search, contains('searchInputFocused.value = focused'));
    expect(mainScreen, isNot(contains('showNativeShellStandIn')));
    expect(mainScreen, isNot(contains('nativeShellOverlaySuppressed')));
    expect(works, isNot(contains('nativeShellOverlaySuppressed')));
    expect(my, isNot(contains('nativeShellOverlaySuppressed')));
    expect(overlay, isNot(contains('nativeShellOverlaySuppressed')));
    expect(overlay, isNot(contains('ValueNotifier')));
    expect(overlay, contains('_nativeShellOverlaySerial'));
    expect(
      overlay,
      contains('Zone.current[_nativeShellOverlayZoneKey] == true'),
    );
    expect(overlay, contains('HarmonyChannel.nativeTopBarActive.value ||'));
    expect(overlay, contains('HarmonyChannel.nativeBottomBarActive.value'));
    expect(overlay, contains('setNativeShellSuppressed(false)'));
    expect(miniPlayer, contains('child: RepaintBoundary('));
  });
}
