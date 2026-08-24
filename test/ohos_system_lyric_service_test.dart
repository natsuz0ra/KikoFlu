import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/ohos_system_lyric_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(OhosSystemLyricService.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('reads native lyric capabilities', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getCapabilities');
      return <String, bool>{'metadataLyric': true, 'desktopLyric': true};
    });
    final service = OhosSystemLyricService(
      channel: channel,
      isOhos: () => true,
    );

    final capabilities = await service.getCapabilities();

    expect(capabilities.metadataLyric, isTrue);
    expect(capabilities.desktopLyric, isTrue);
  });

  test('returns unsupported when capability channel fails', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    final service = OhosSystemLyricService(
      channel: channel,
      isOhos: () => true,
    );

    final capabilities = await service.getCapabilities();

    expect(capabilities.metadataLyric, isFalse);
    expect(capabilities.desktopLyric, isFalse);
  });

  test(
    'caches live-session capabilities but retries pre-session responses',
    () async {
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls++;
        return <String, bool>{
          'metadataLyric': calls > 1,
          'desktopLyric': calls > 1,
        };
      });
      final service = OhosSystemLyricService(
        channel: channel,
        isOhos: () => true,
      );

      expect((await service.getCapabilities()).metadataLyric, isFalse);
      expect((await service.getCapabilities()).desktopLyric, isTrue);
      expect((await service.getCapabilities()).desktopLyric, isTrue);
      expect(calls, 2);

      service.invalidateNativeState();
      expect((await service.getCapabilities()).desktopLyric, isTrue);
      expect(calls, 3);
    },
  );

  test(
    'deduplicates current line and keeps the latest pending content',
    () async {
      final calls = <MethodCall>[];
      final firstWrite = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (calls.length == 1) await firstWrite.future;
        return true;
      });
      final service = OhosSystemLyricService(
        channel: channel,
        isOhos: () => true,
      );
      const first = OhosLyricContent(
        lyric: '[00:00.000]first',
        singleLyricText: 'first',
      );
      const skipped = OhosLyricContent(
        lyric: '[00:00.000]second',
        singleLyricText: 'second',
      );
      const latest = OhosLyricContent(
        lyric: '[00:00.000]third',
        singleLyricText: 'third',
      );

      final firstResult = service.setLyricContent(first);
      final skippedResult = service.setLyricContent(skipped);
      final latestResult = service.setLyricContent(latest);
      firstWrite.complete();

      expect(await firstResult, isTrue);
      expect(await skippedResult, isTrue);
      expect(await latestResult, isTrue);
      expect(calls, hasLength(2));
      expect(calls.last.arguments['singleLyricText'], 'third');

      expect(await service.setLyricContent(latest), isTrue);
      expect(calls, hasLength(2));
    },
  );

  test('does not invoke the HarmonyOS channel on another platform', () async {
    var invoked = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      invoked = true;
      return true;
    });
    final service = OhosSystemLyricService(
      channel: channel,
      isOhos: () => false,
    );

    expect(
      await service.setLyricContent(
        const OhosLyricContent(lyric: 'secret', singleLyricText: 'secret'),
      ),
      isFalse,
    );
    expect(await service.setDesktopLyricVisible(true), isFalse);
    expect(invoked, isFalse);
  });

  test(
    'invalidating native state resends otherwise deduplicated values',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });
      final service = OhosSystemLyricService(
        channel: channel,
        isOhos: () => true,
      );
      const content = OhosLyricContent(
        lyric: '[00:00.000]line',
        singleLyricText: 'line',
      );

      await service.setLyricContent(content);
      await service.setDesktopLyricVisible(true);
      await service.setLyricContent(content);
      await service.setDesktopLyricVisible(true);
      expect(calls, hasLength(2));

      service.invalidateNativeState();
      await service.setLyricContent(content);
      await service.setDesktopLyricVisible(true);
      expect(calls, hasLength(4));
    },
  );

  test('failed writes are not cached and can be retried', () async {
    var contentCalls = 0;
    var visibilityCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setLyricContent') {
        contentCalls++;
        return contentCalls > 1;
      }
      if (call.method == 'setDesktopLyricVisible') {
        visibilityCalls++;
        return visibilityCalls > 1;
      }
      return false;
    });
    final service = OhosSystemLyricService(
      channel: channel,
      isOhos: () => true,
    );
    const content = OhosLyricContent(
      lyric: '[00:00.000]retry',
      singleLyricText: 'retry',
    );

    expect(await service.setLyricContent(content), isFalse);
    expect(await service.setLyricContent(content), isTrue);
    expect(await service.setDesktopLyricVisible(true), isFalse);
    expect(await service.setDesktopLyricVisible(true), isTrue);
    expect(contentCalls, 2);
    expect(visibilityCalls, 2);
  });

  test('reports a system-initiated desktop lyric close', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    final service = OhosSystemLyricService(
      channel: channel,
      isOhos: () => true,
    );
    final externalChanges = <bool>[];
    final subscription = service.onExternalDesktopVisibilityChanged.listen(
      externalChanges.add,
    );

    expect(await service.setDesktopLyricVisible(true), isTrue);
    await _sendNativeLyricCall(
      messenger,
      const MethodCall('onDesktopLyricVisibilityChanged', true),
    );
    expect(externalChanges, isEmpty);

    await _sendNativeLyricCall(
      messenger,
      const MethodCall('onDesktopLyricVisibilityChanged', false),
    );
    expect(externalChanges, [false]);

    // The native event updates the visibility cache, so the provider's state
    // reconciliation does not send a redundant hide command back to OHOS.
    expect(await service.setDesktopLyricVisible(false), isTrue);
    expect(calls, hasLength(1));
    await subscription.cancel();
  });

  test(
    'does not report an app-requested desktop lyric hide as external',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async => true);
      final service = OhosSystemLyricService(
        channel: channel,
        isOhos: () => true,
      );
      final externalChanges = <bool>[];
      final subscription = service.onExternalDesktopVisibilityChanged.listen(
        externalChanges.add,
      );

      expect(await service.setDesktopLyricVisible(false), isTrue);
      await _sendNativeLyricCall(
        messenger,
        const MethodCall('onDesktopLyricVisibilityChanged', false),
      );

      expect(externalChanges, isEmpty);
      await subscription.cancel();
    },
  );
}

Future<void> _sendNativeLyricCall(
  TestDefaultBinaryMessenger messenger,
  MethodCall call,
) async {
  final reply = Completer<void>();
  await messenger.handlePlatformMessage(
    OhosSystemLyricService.channelName,
    const StandardMethodCodec().encodeMethodCall(call),
    (_) => reply.complete(),
  );
  await reply.future;
}
