import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'keeps native top treatment cheap and the My filter structurally equal',
    () {
      final source = File(
        'ohos/entry/src/main/ets/immersive/ImmersiveTopBar.ets',
      ).readAsStringSync();

      expect(source, contains('HdsImmersiveCapsuleMaterial'));
      expect(source, contains('hdsMaterial.MaterialType.IMMERSIVE'));
      expect(source, isNot(contains('.linearGradient({')));
      expect(source, isNot(contains('.linearGradientBlur(')));
      expect(source, contains('const SECONDARY_FILTER_MIN_WIDTH = 104;'));
      expect(source, contains('const SECONDARY_FILTER_MAX_WIDTH = 152;'));
      expect(source, contains('const SECONDARY_MENU_WIDTH = 152;'));
      expect(source, contains('.width(this.secondaryFilterWidth())'));
      expect(source, contains('.width(SECONDARY_MENU_WIDTH)'));
      expect(
        RegExp(r'Blank\(\)\.layoutWeight\(1\)').allMatches(source).length,
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
    expect(mainScreen, contains('if (keyboardVisible)'));
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
    expect(my, contains('final nativeTabIndex = _settledTabIndex.clamp'));
    expect(my, contains('_tabController.animation?.addListener'));
  });

  test('ordinary page routes preserve the confirmed native layout latch', () {
    final mainScreen = File(
      'lib/src/screens/main_screen.dart',
    ).readAsStringSync();
    final channel = File(
      'lib/src/platform/harmony_channel.dart',
    ).readAsStringSync();

    expect(
      mainScreen,
      allOf(
        contains('NativeShellRouteDisposition.flutterPage'),
        contains('preserveBottomTakeover'),
        contains('preserveTopTakeover'),
        contains('await HarmonyChannel.setNativeBottomBar(false);'),
        contains('await HarmonyChannel.setNativeTopBar(false);'),
        contains(
          'final keepMainLayout = keepsNativeShell || temporarilyCovered;',
        ),
      ),
    );
    expect(
      mainScreen,
      matches(
        RegExp(
          r'bottomEnabled:\s*keepMainLayout\s*&&\s*!isLandscape\s*&&\s*useLiquidGlass',
        ),
      ),
    );
    expect(
      mainScreen,
      matches(
        RegExp(
          r'useNativeOhosBottom\s*=\s*keepMainLayout\s*&&\s*!isLandscape\s*&&\s*HarmonyChannel\.nativeBottomBarActive\.value',
        ),
      ),
    );
    expect(mainScreen, isNot(contains('setNativeShellSuppressed(')));
    expect(channel, isNot(contains('_routeShellSuppressed')));
  });
}
