import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/platform/harmony_channel.dart';
import 'package:kikoeru_flutter/src/platform/native_shell_route_observer.dart';

void main() {
  test('keeps the native shell for PopupRoute overlays', () {
    final observer = NativeShellRouteObserver();
    addTearDown(observer.revision.dispose);
    final mainRoute = MaterialPageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
    );
    final popupRoute = RawDialogRoute<void>(
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
    );

    observer.didPush(mainRoute, null);
    observer.didPush(popupRoute, mainRoute);

    expect(observer.keepsShellVisibleFor(mainRoute), isTrue);
  });

  test('hides the native shell when another page route is pushed', () {
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

    observer.didPop(detailRoute, mainRoute);
    expect(observer.keepsShellVisibleFor(mainRoute), isTrue);
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
      observer.nativeTopPageAbove(mainRoute),
      HarmonyTopBarPage.searchResult,
    );
  });
}
