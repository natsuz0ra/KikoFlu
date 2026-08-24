import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/platform/harmony_channel.dart';
import 'package:kikoeru_flutter/src/platform/native_shell_route_observer.dart';

void main() {
  test('keeps route ownership while suppressing nested PopupRoutes', () {
    final popupVisibility = <bool>[];
    final observer = NativeShellRouteObserver(
      onPopupVisibilityChanged: popupVisibility.add,
    );
    addTearDown(observer.revision.dispose);
    final mainRoute = MaterialPageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
    );
    final popupRoute = RawDialogRoute<void>(
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    final nestedPopupRoute = RawDialogRoute<void>(
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
    );

    observer.didPush(mainRoute, null);
    observer.didPush(popupRoute, mainRoute);

    expect(observer.keepsShellVisibleFor(mainRoute), isTrue);
    expect(
      observer.dispositionAbove(mainRoute),
      NativeShellRouteDisposition.mainShell,
    );
    expect(observer.popupVisible, isTrue);
    expect(popupVisibility, [true]);

    observer.didPush(nestedPopupRoute, popupRoute);
    observer.didPop(nestedPopupRoute, popupRoute);
    expect(observer.popupVisible, isTrue);
    expect(popupVisibility, [true]);

    observer.didPop(popupRoute, mainRoute);
    expect(observer.popupVisible, isFalse);
    expect(popupVisibility, [true, false]);
  });

  test('marks an ordinary page as temporary main-shell coverage', () {
    final observer = NativeShellRouteObserver();
    addTearDown(observer.revision.dispose);
    final mainRoute = MaterialPageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
    );
    final detailRoute = MaterialPageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
    );

    observer.didPush(mainRoute, null);
    observer.didPush(detailRoute, mainRoute);
    expect(observer.keepsShellVisibleFor(mainRoute), isFalse);
    expect(
      observer.dispositionAbove(mainRoute),
      NativeShellRouteDisposition.flutterPage,
    );

    observer.didPop(detailRoute, mainRoute);
    expect(observer.keepsShellVisibleFor(mainRoute), isTrue);
    expect(
      observer.dispositionAbove(mainRoute),
      NativeShellRouteDisposition.mainShell,
    );
  });

  test('exposes a route-scoped native top owner through popup overlays', () {
    final observer = NativeShellRouteObserver();
    addTearDown(observer.revision.dispose);
    final mainRoute = MaterialPageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
    );
    final resultRoute = HarmonyNativeTopPageRoute<void>(
      nativeTopPage: HarmonyTopBarPage.searchResult,
      builder: (_) => const SizedBox.shrink(),
    );
    final popupRoute = RawDialogRoute<void>(
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
    );

    observer.didPush(mainRoute, null);
    observer.didPush(resultRoute, mainRoute);
    observer.didPush(popupRoute, resultRoute);

    expect(observer.keepsShellVisibleFor(mainRoute), isFalse);
    expect(
      observer.dispositionAbove(mainRoute),
      NativeShellRouteDisposition.nativeTopPage,
    );
    expect(
      observer.nativeTopPageAbove(mainRoute),
      HarmonyTopBarPage.searchResult,
    );
  });
}
