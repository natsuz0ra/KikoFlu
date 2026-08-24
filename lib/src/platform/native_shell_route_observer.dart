import 'dart:async';

import 'package:flutter/material.dart';

import 'harmony_channel.dart';

class HarmonyNativeTopPageRoute<T> extends MaterialPageRoute<T> {
  HarmonyNativeTopPageRoute({
    required this.nativeTopPage,
    required super.builder,
    super.settings,
  });

  final HarmonyTopBarPage nativeTopPage;
}

enum NativeShellRouteDisposition {
  /// The main shell route is current, or is only covered by popup routes.
  mainShell,

  /// A regular Flutter page covers the main shell temporarily.
  ///
  /// ArkUI must be hidden, but the confirmed native takeover and Flutter
  /// layout stay latched until the page is popped. That keeps the outgoing
  /// main page from rebuilding its bottom bar and MiniPlayer mid-transition.
  flutterPage,

  /// A nested page explicitly owns the native top bar.
  nativeTopPage,
}

/// Tracks whether a page route, rather than a transient popup, covers the
/// application shell.
///
/// [ModalRoute.isCurrent] also becomes false for dialogs and popup menus. The
/// native HarmonyOS shell must stay mounted for those overlays, while a real
/// page push still needs to hand control back to Flutter.
class NativeShellRouteObserver extends NavigatorObserver {
  NativeShellRouteObserver({this.onPopupVisibilityChanged});

  final FutureOr<void> Function(bool visible)? onPopupVisibilityChanged;
  final List<Route<dynamic>> _routes = <Route<dynamic>>[];
  bool _popupVisible = false;

  /// Changes whenever the root navigator route stack changes.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  bool get popupVisible => _popupVisible;

  NativeShellRouteDisposition dispositionAbove(Route<dynamic>? shellRoute) {
    final coveringRoute = _lastPageRouteAbove(shellRoute);
    if (coveringRoute == null) return NativeShellRouteDisposition.mainShell;
    return coveringRoute is HarmonyNativeTopPageRoute<dynamic>
        ? NativeShellRouteDisposition.nativeTopPage
        : NativeShellRouteDisposition.flutterPage;
  }

  bool keepsShellVisibleFor(Route<dynamic>? shellRoute) =>
      dispositionAbove(shellRoute) == NativeShellRouteDisposition.mainShell;

  HarmonyTopBarPage? nativeTopPageAbove(Route<dynamic>? shellRoute) {
    final coveringRoute = _lastPageRouteAbove(shellRoute);
    return coveringRoute is HarmonyNativeTopPageRoute<dynamic>
        ? coveringRoute.nativeTopPage
        : null;
  }

  Route<dynamic>? _lastPageRouteAbove(Route<dynamic>? shellRoute) {
    if (shellRoute == null) return null;
    final shellIndex = _routes.indexOf(shellRoute);
    if (shellIndex < 0) return shellRoute.isCurrent ? null : shellRoute;

    Route<dynamic>? coveringRoute;
    for (final route in _routes.skip(shellIndex + 1)) {
      if (route is! PopupRoute<dynamic>) coveringRoute = route;
    }
    return coveringRoute;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null && !_routes.contains(previousRoute)) {
      _routes.add(previousRoute);
    }
    _routes.remove(route);
    _routes.add(route);
    _notifyChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _routes.remove(route);
    _notifyChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _routes.remove(route);
    _notifyChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final oldIndex = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (oldRoute != null) _routes.remove(oldRoute);
    if (newRoute != null) {
      _routes.remove(newRoute);
      if (oldIndex >= 0 && oldIndex <= _routes.length) {
        _routes.insert(oldIndex, newRoute);
      } else {
        _routes.add(newRoute);
      }
    }
    _notifyChanged();
  }

  void _notifyChanged() {
    final popupVisible = _routes.any((route) => route is PopupRoute<dynamic>);
    if (_popupVisible != popupVisible) {
      _popupVisible = popupVisible;
      onPopupVisibilityChanged?.call(popupVisible);
    }
    revision.value++;
  }
}

final nativeShellRouteObserver = NativeShellRouteObserver(
  onPopupVisibilityChanged: (visible) {
    unawaited(HarmonyChannel.setNativeShellSuppressed(visible));
  },
);
