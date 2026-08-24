import 'dart:async';

import 'package:flutter/services.dart';

import '../platform/runtime_platform.dart';
import 'log_service.dart';

class OhosLyricCapabilities {
  const OhosLyricCapabilities({
    required this.metadataLyric,
    required this.desktopLyric,
  });

  static const unsupported = OhosLyricCapabilities(
    metadataLyric: false,
    desktopLyric: false,
  );

  final bool metadataLyric;
  final bool desktopLyric;
}

class OhosLyricContent {
  const OhosLyricContent({required this.lyric, required this.singleLyricText});

  final String lyric;
  final String singleLyricText;

  @override
  bool operator ==(Object other) =>
      other is OhosLyricContent &&
      other.lyric == lyric &&
      other.singleLyricText == singleLyricText;

  @override
  int get hashCode => Object.hash(lyric, singleLyricText);
}

class OhosSystemLyricService {
  OhosSystemLyricService({MethodChannel? channel, bool Function()? isOhos})
    : _channel = channel ?? const MethodChannel(channelName),
      _isOhos = isOhos ?? (() => runtimePlatform.isOhos) {
    if (_isOhos()) {
      _channel.setMethodCallHandler(_handleNativeCall);
    }
  }

  static const channelName = 'com.kikoeru.audio_service/ohos_lyric';
  static final instance = OhosSystemLyricService();

  final MethodChannel _channel;
  final bool Function() _isOhos;
  final _externalDesktopVisibilityController =
      StreamController<bool>.broadcast();

  /// Visibility changes initiated by the system surface instead of this app.
  Stream<bool> get onExternalDesktopVisibilityChanged =>
      _externalDesktopVisibilityController.stream;

  OhosLyricContent? _lastContent;
  _PendingContent? _pendingContent;
  bool _drainingContent = false;

  bool? _lastDesktopVisible;
  bool? _desiredDesktopVisible;
  _PendingVisibility? _pendingVisibility;
  bool _drainingVisibility = false;
  OhosLyricCapabilities? _cachedCapabilities;
  int _nativeStateEpoch = 0;

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onDesktopLyricVisibilityChanged') return;

    final visible = call.arguments == true;
    _lastDesktopVisible = visible;
    if (_desiredDesktopVisible == visible) return;

    // A different value means the system surface changed independently, such
    // as when the user closes the desktop lyric window from its own controls.
    _desiredDesktopVisible = visible;
    _externalDesktopVisibilityController.add(visible);
  }

  /// Invalidates values cached for the current native AVSession.
  ///
  /// audio_service may destroy and recreate its AVSession while the Dart
  /// service singleton stays alive. In-flight writes from the old session are
  /// tagged with the previous epoch so they cannot repopulate these caches.
  void invalidateNativeState() {
    _nativeStateEpoch++;
    _lastContent = null;
    _lastDesktopVisible = null;
    _cachedCapabilities = null;
  }

  Future<OhosLyricCapabilities> getCapabilities() async {
    if (!_isOhos()) return OhosLyricCapabilities.unsupported;
    final cached = _cachedCapabilities;
    if (cached != null) return cached;

    final epoch = _nativeStateEpoch;
    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'getCapabilities',
      );
      final capabilities = OhosLyricCapabilities(
        metadataLyric: result?['metadataLyric'] == true,
        desktopLyric: result?['desktopLyric'] == true,
      );
      // A negative response commonly means the AVSession has not been created
      // yet, so only cache a capability result tied to a live session.
      if (epoch == _nativeStateEpoch && capabilities.metadataLyric) {
        _cachedCapabilities = capabilities;
      }
      return capabilities;
    } catch (error) {
      LogService.instance.captureOutput(
        '[OhosSystemLyric] capability query failed: $error',
      );
      return OhosLyricCapabilities.unsupported;
    }
  }

  Future<bool> setLyricContent(OhosLyricContent content) {
    if (!_isOhos()) return Future.value(false);
    if (content == _lastContent && _pendingContent == null) {
      return Future.value(true);
    }

    final completer = Completer<bool>();
    _pendingContent?.completeSuperseded();
    _pendingContent = _PendingContent(content, completer, _nativeStateEpoch);
    if (!_drainingContent) {
      unawaited(_drainContent());
    }
    return completer.future;
  }

  Future<void> _drainContent() async {
    _drainingContent = true;
    try {
      while (_pendingContent != null) {
        final pending = _pendingContent!;
        _pendingContent = null;
        if (pending.content == _lastContent) {
          pending.complete(true);
          continue;
        }

        var success = false;
        try {
          success =
              await _channel
                  .invokeMethod<bool>('setLyricContent', <String, Object>{
                    'lyric': pending.content.lyric,
                    'singleLyricText': pending.content.singleLyricText,
                  }) ==
              true;
        } catch (error) {
          LogService.instance.captureOutput(
            '[OhosSystemLyric] lyric update failed: $error',
          );
        }
        if (success && pending.epoch == _nativeStateEpoch) {
          _lastContent = pending.content;
        }
        pending.complete(success);
      }
    } finally {
      _drainingContent = false;
      if (_pendingContent != null) unawaited(_drainContent());
    }
  }

  Future<bool> setDesktopLyricVisible(bool visible) {
    if (!_isOhos()) return Future.value(false);
    _desiredDesktopVisible = visible;
    if (_lastDesktopVisible == visible && _pendingVisibility == null) {
      return Future.value(true);
    }

    final completer = Completer<bool>();
    _pendingVisibility?.completeSuperseded();
    _pendingVisibility = _PendingVisibility(
      visible,
      completer,
      _nativeStateEpoch,
    );
    if (!_drainingVisibility) {
      unawaited(_drainVisibility());
    }
    return completer.future;
  }

  Future<void> _drainVisibility() async {
    _drainingVisibility = true;
    try {
      while (_pendingVisibility != null) {
        final pending = _pendingVisibility!;
        _pendingVisibility = null;
        if (_lastDesktopVisible == pending.visible) {
          pending.complete(true);
          continue;
        }

        var success = false;
        try {
          success =
              await _channel.invokeMethod<bool>(
                'setDesktopLyricVisible',
                <String, Object>{'visible': pending.visible},
              ) ==
              true;
        } catch (error) {
          LogService.instance.captureOutput(
            '[OhosSystemLyric] desktop lyric update failed: $error',
          );
        }
        if (success && pending.epoch == _nativeStateEpoch) {
          _lastDesktopVisible = pending.visible;
        }
        pending.complete(success);
      }
    } finally {
      _drainingVisibility = false;
      if (_pendingVisibility != null) unawaited(_drainVisibility());
    }
  }
}

class _PendingContent {
  _PendingContent(this.content, this.completer, this.epoch);

  final OhosLyricContent content;
  final Completer<bool> completer;
  final int epoch;

  void complete(bool value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  void completeSuperseded() => complete(true);
}

class _PendingVisibility {
  _PendingVisibility(this.visible, this.completer, this.epoch);

  final bool visible;
  final Completer<bool> completer;
  final int epoch;

  void complete(bool value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  void completeSuperseded() => complete(true);
}
