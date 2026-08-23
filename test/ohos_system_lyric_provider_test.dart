import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/lyric.dart';
import 'package:kikoeru_flutter/src/providers/ohos_system_lyric_provider.dart';
import 'package:kikoeru_flutter/src/services/ohos_system_lyric_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('serializes display lyrics as standard millisecond LRC', () {
    final result = lyricsToStandardLrc([
      LyricLine(
        startTime: const Duration(minutes: 1, seconds: 2, milliseconds: 34),
        endTime: const Duration(minutes: 1, seconds: 3),
        text: ' first\nline ',
      ),
      LyricLine(
        startTime: const Duration(milliseconds: -20),
        endTime: Duration.zero,
        text: 'zero',
      ),
      LyricLine(
        startTime: const Duration(seconds: 3),
        endTime: const Duration(seconds: 4),
        text: '  ',
      ),
      LyricLine(
        startTime: const Duration(seconds: 4),
        endTime: const Duration(seconds: 5),
        text: '♪ - ♪',
      ),
    ]);

    expect(result, '[01:02.034]first line\n[00:00.000]zero');
  });

  test('clears old lyric before publishing a new track', () async {
    final service = _RecordingLyricService();
    final synchronizer = OhosSystemLyricSynchronizer(service);

    await synchronizer.submit(
      OhosSystemLyricSnapshot(
        trackId: 'track-a',
        lyrics: [_line('a')],
        currentLyric: 'a',
        privacyEnabled: false,
        desktopVisible: true,
      ),
    );
    await synchronizer.submit(
      OhosSystemLyricSnapshot(
        trackId: 'track-b',
        lyrics: [_line('b')],
        currentLyric: 'b',
        privacyEnabled: false,
        desktopVisible: true,
      ),
    );

    expect(service.contents.map((content) => content.lyric), [
      '[00:00.000]a',
      '',
      '[00:00.000]b',
    ]);
  });

  test('privacy hides the window before clearing lyric metadata', () async {
    final service = _RecordingLyricService();
    final synchronizer = OhosSystemLyricSynchronizer(service);

    await synchronizer.submit(
      OhosSystemLyricSnapshot(
        trackId: 'track-a',
        lyrics: [_line('private')],
        currentLyric: 'private',
        privacyEnabled: true,
        desktopVisible: true,
      ),
    );

    expect(service.operations, ['visible:false', 'content:']);
    expect(service.contents.single.singleLyricText, isEmpty);
  });

  test(
    'a player-state transition invalidates native deduplication state',
    () async {
      final service = _RecordingLyricService();
      final synchronizer = OhosSystemLyricSynchronizer(service);
      final firstToken = Object();
      final secondToken = Object();
      final snapshot = OhosSystemLyricSnapshot(
        trackId: 'track-a',
        lyrics: [_line('line')],
        currentLyric: 'line',
        privacyEnabled: false,
        desktopVisible: true,
        nativeSessionToken: firstToken,
      );

      await synchronizer.submit(snapshot);
      await synchronizer.submit(snapshot);
      expect(service.invalidations, 1);

      await synchronizer.submit(
        OhosSystemLyricSnapshot(
          trackId: snapshot.trackId,
          lyrics: snapshot.lyrics,
          currentLyric: snapshot.currentLyric,
          privacyEnabled: snapshot.privacyEnabled,
          desktopVisible: snapshot.desktopVisible,
          nativeSessionToken: secondToken,
        ),
      );
      expect(service.invalidations, 2);
    },
  );

  test(
    'privacy keeps desired visibility and restores it when disabled',
    () async {
      final service = _RecordingLyricService();
      final synchronizer = OhosSystemLyricSynchronizer(service);
      final visibleSnapshot = OhosSystemLyricSnapshot(
        trackId: 'track-a',
        lyrics: [_line('line')],
        currentLyric: 'line',
        privacyEnabled: false,
        desktopVisible: true,
      );

      await synchronizer.submit(visibleSnapshot);
      await synchronizer.submit(
        OhosSystemLyricSnapshot(
          trackId: 'track-a',
          lyrics: [_line('line')],
          currentLyric: 'line',
          privacyEnabled: true,
          desktopVisible: true,
        ),
      );
      await synchronizer.submit(visibleSnapshot);

      expect(
        service.operations,
        containsAllInOrder([
          'visible:true',
          'visible:false',
          'content:',
          'content:[00:00.000]line',
          'visible:true',
        ]),
      );
    },
  );
}

LyricLine _line(String text) => LyricLine(
  startTime: Duration.zero,
  endTime: const Duration(seconds: 1),
  text: text,
);

class _RecordingLyricService extends OhosSystemLyricService {
  _RecordingLyricService()
    : super(
        channel: const MethodChannel('test/ohos_system_lyric'),
        isOhos: () => true,
      );

  final contents = <OhosLyricContent>[];
  final operations = <String>[];
  int invalidations = 0;

  @override
  void invalidateNativeState() {
    invalidations++;
  }

  @override
  Future<bool> setLyricContent(OhosLyricContent content) async {
    contents.add(content);
    operations.add('content:${content.lyric}');
    return true;
  }

  @override
  Future<bool> setDesktopLyricVisible(bool visible) async {
    operations.add('visible:$visible');
    return true;
  }
}
