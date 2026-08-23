import 'dart:async';

import 'package:flutter/widgets.dart';

import 'harmony_channel.dart';
import 'runtime_platform.dart';

Future<void> _nativeShellOverlaySerial = Future<void>.value();
final Object _nativeShellOverlayZoneKey = Object();

bool get _hasConfirmedNativeShell =>
    HarmonyChannel.nativeTopBarActive.value ||
    HarmonyChannel.nativeBottomBarActive.value;

/// Runs a Flutter overlay while temporarily removing the ArkUI shell siblings
/// above FlutterPage. Native takeover remains active, so Flutter does not mount
/// replacement bars while the popup is visible. Calls are serialized so one
/// popup cannot restore the shell while another popup still owns it.
Future<T?> showWithNativeShellSuppressed<T>(
  BuildContext context,
  Future<T?> Function() showOverlay,
) async {
  // A popup opened from inside another suppressed popup already owns the
  // native-shell lease. Re-enter directly so it cannot wait on its own turn.
  if (Zone.current[_nativeShellOverlayZoneKey] == true) {
    return showOverlay();
  }

  if (!runtimePlatform.usesNativeHarmonyGlass || !_hasConfirmedNativeShell) {
    return showOverlay();
  }

  final previous = _nativeShellOverlaySerial;
  final turn = Completer<void>();
  _nativeShellOverlaySerial = turn.future;
  await previous;

  var modernSuppression = false;
  var legacySuppression = false;
  var suppressionAttempted = false;
  try {
    // The route may have disappeared while another popup owned the lease.
    if (!context.mounted) return null;
    if (!runtimePlatform.usesNativeHarmonyGlass || !_hasConfirmedNativeShell) {
      return await showOverlay();
    }

    suppressionAttempted = true;
    modernSuppression = await HarmonyChannel.setNativeShellSuppressed(true);
    if (!modernSuppression) {
      legacySuppression = await HarmonyChannel.setNativeBarsHidden(true);
    }

    if (!context.mounted) return null;

    // If both channel methods fail, preserve the ordinary Flutter behavior
    // instead of turning the tap into a no-op.
    return await runZoned<Future<T?>>(
      showOverlay,
      zoneValues: <Object?, Object?>{_nativeShellOverlayZoneKey: true},
    );
  } finally {
    try {
      if (suppressionAttempted) {
        if (modernSuppression) {
          await HarmonyChannel.setNativeShellSuppressed(false);
        } else {
          if (legacySuppression) {
            await HarmonyChannel.setNativeBarsHidden(false);
          }
          await HarmonyChannel.setNativeShellSuppressed(false);
        }
      }
    } finally {
      if (!turn.isCompleted) turn.complete();
    }
  }
}
