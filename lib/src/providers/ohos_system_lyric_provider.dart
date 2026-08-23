import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lyric.dart';
import '../platform/runtime_platform.dart';
import '../services/ohos_system_lyric_service.dart';
import 'audio_provider.dart';
import 'floating_lyric_provider.dart';
import 'lyric_provider.dart';
import 'settings_provider.dart';

final ohosSystemLyricServiceProvider = Provider<OhosSystemLyricService>((ref) {
  return OhosSystemLyricService.instance;
});

final ohosSystemLyricSynchronizerProvider =
    Provider<OhosSystemLyricSynchronizer>((ref) {
      return OhosSystemLyricSynchronizer(
        ref.watch(ohosSystemLyricServiceProvider),
      );
    });

/// Keeps HarmonyOS AVMetadata lyrics alive even when no lyric UI is mounted.
final ohosSystemLyricSyncProvider = Provider<void>((ref) {
  if (!runtimePlatform.isOhos) return;

  final synchronizer = ref.watch(ohosSystemLyricSynchronizerProvider);
  final track = ref.watch(currentTrackProvider).value;
  final lyricState = ref.watch(lyricControllerProvider);
  final currentLyric = ref.watch(currentLyricTextProvider);
  final privacyEnabled = ref.watch(privacyModeSettingsProvider).enabled;
  final desktopVisible = ref.watch(floatingLyricEnabledProvider);

  // A player-state transition retries values that may have arrived before the
  // native audio_service created its AVSession.
  final nativeSessionToken = ref.watch(playerStateProvider).value;

  unawaited(
    synchronizer.submit(
      OhosSystemLyricSnapshot(
        trackId: track?.id,
        lyrics: lyricState.isLoading ? const [] : lyricState.displayLyrics,
        currentLyric: lyricState.isLoading ? null : currentLyric,
        privacyEnabled: privacyEnabled,
        desktopVisible: desktopVisible,
        nativeSessionToken: nativeSessionToken,
      ),
    ),
  );
});

class OhosSystemLyricSnapshot {
  const OhosSystemLyricSnapshot({
    required this.trackId,
    required this.lyrics,
    required this.currentLyric,
    required this.privacyEnabled,
    required this.desktopVisible,
    this.nativeSessionToken,
  });

  final String? trackId;
  final List<LyricLine> lyrics;
  final String? currentLyric;
  final bool privacyEnabled;
  final bool desktopVisible;
  final Object? nativeSessionToken;
}

class OhosSystemLyricSynchronizer {
  OhosSystemLyricSynchronizer(this._service);

  static const _emptyContent = OhosLyricContent(lyric: '', singleLyricText: '');

  final OhosSystemLyricService _service;
  OhosSystemLyricSnapshot? _pending;
  bool _draining = false;
  String? _lastTrackId;
  bool _hasSeenTrack = false;
  Object? _lastNativeSessionToken;
  bool _hasSeenNativeSessionToken = false;

  Future<void> submit(OhosSystemLyricSnapshot snapshot) async {
    _pending = snapshot;
    if (_draining) return;

    _draining = true;
    try {
      while (_pending != null) {
        final next = _pending!;
        _pending = null;
        await _apply(next);
      }
    } finally {
      _draining = false;
      if (_pending != null) unawaited(submit(_pending!));
    }
  }

  Future<void> _apply(OhosSystemLyricSnapshot snapshot) async {
    if (!_hasSeenNativeSessionToken ||
        !identical(snapshot.nativeSessionToken, _lastNativeSessionToken)) {
      _hasSeenNativeSessionToken = true;
      _lastNativeSessionToken = snapshot.nativeSessionToken;
      _service.invalidateNativeState();
    }

    if (snapshot.privacyEnabled) {
      // Hide first so a metadata update cannot briefly reveal private text.
      await _service.setDesktopLyricVisible(false);
      await _service.setLyricContent(_emptyContent);
      return;
    }

    final trackChanged = _hasSeenTrack && snapshot.trackId != _lastTrackId;
    _hasSeenTrack = true;
    _lastTrackId = snapshot.trackId;
    if (trackChanged) {
      await _service.setLyricContent(_emptyContent);
    }

    if (snapshot.trackId == null) {
      await _service.setLyricContent(_emptyContent);
      await _service.setDesktopLyricVisible(false);
      return;
    }

    await _service.setLyricContent(
      OhosLyricContent(
        lyric: lyricsToStandardLrc(snapshot.lyrics),
        singleLyricText: snapshot.currentLyric?.trim() ?? '',
      ),
    );
    await _service.setDesktopLyricVisible(snapshot.desktopVisible);
  }
}

String lyricsToStandardLrc(List<LyricLine> lyrics) {
  return lyrics
      .map((line) {
        final totalMilliseconds = line.startTime.isNegative
            ? 0
            : line.startTime.inMilliseconds;
        final minutes = totalMilliseconds ~/ Duration.millisecondsPerMinute;
        final seconds =
            (totalMilliseconds ~/ Duration.millisecondsPerSecond) % 60;
        final milliseconds = totalMilliseconds % 1000;
        final text = line.text.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
        if (_isLyricPlaceholder(text)) return null;
        return '[${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}.'
            '${milliseconds.toString().padLeft(3, '0')}]$text';
      })
      .whereType<String>()
      .join('\n');
}

bool _isLyricPlaceholder(String text) {
  if (text.isEmpty) return true;
  return RegExp(r'^♪\s*-\s*♪$').hasMatch(text);
}
