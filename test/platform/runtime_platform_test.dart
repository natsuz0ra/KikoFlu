import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/platform/runtime_platform.dart';

void main() {
  group('RuntimePlatform', () {
    test('classifies HarmonyOS as mobile without desktop capabilities', () {
      final platform = RuntimePlatform.fromOperatingSystem('ohos');

      expect(platform.kind, RuntimePlatformKind.ohos);
      expect(platform.isOhos, isTrue);
      expect(platform.isMobile, isTrue);
      expect(platform.isDesktop, isFalse);
      expect(platform.usesNativeHarmonyGlass, isTrue);
      expect(platform.supportsDesktopWindow, isFalse);
      expect(platform.supportsMpvBackend, isFalse);
      expect(platform.supportsSqfliteFfi, isFalse);
      expect(platform.supportsSmtc, isFalse);
      expect(platform.supportsAudioSessionConfiguration, isTrue);
      expect(platform.usesDesktopStoragePaths, isFalse);
    });

    test('preserves Android capabilities', () {
      final platform = RuntimePlatform.fromOperatingSystem('android');

      expect(platform.isMobile, isTrue);
      expect(platform.supportsMpvBackend, isTrue);
      expect(platform.supportsDesktopWindow, isFalse);
      expect(platform.supportsAudioSessionConfiguration, isTrue);
      expect(platform.usesNativeHarmonyGlass, isFalse);
    });

    test('preserves iOS capabilities', () {
      final platform = RuntimePlatform.fromOperatingSystem('ios');

      expect(platform.isMobile, isTrue);
      expect(platform.supportsMpvBackend, isFalse);
      expect(platform.supportsAudioSessionConfiguration, isTrue);
      expect(platform.usesNativeHarmonyGlass, isFalse);
    });

    test('preserves desktop capabilities', () {
      for (final operatingSystem in const ['windows', 'macos', 'linux']) {
        final platform = RuntimePlatform.fromOperatingSystem(operatingSystem);

        expect(platform.isDesktop, isTrue, reason: operatingSystem);
        expect(platform.isMobile, isFalse, reason: operatingSystem);
        expect(platform.supportsDesktopWindow, isTrue, reason: operatingSystem);
        expect(platform.supportsMpvBackend, isTrue, reason: operatingSystem);
        expect(
          platform.usesDesktopStoragePaths,
          isTrue,
          reason: operatingSystem,
        );
      }
    });

    test('classifies unknown operating systems conservatively', () {
      final platform = RuntimePlatform.fromOperatingSystem('fuchsia');

      expect(platform.kind, RuntimePlatformKind.other);
      expect(platform.isMobile, isFalse);
      expect(platform.isDesktop, isFalse);
      expect(platform.supportsDesktopWindow, isFalse);
      expect(platform.supportsMpvBackend, isFalse);
    });
  });
}
