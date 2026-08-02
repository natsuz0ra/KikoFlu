import 'dart:io' show Platform;

enum RuntimePlatformKind {
  android,
  ios,
  ohos,
  windows,
  macos,
  linux,
  other,
}

class RuntimePlatform {
  const RuntimePlatform._(this.kind);

  factory RuntimePlatform.fromOperatingSystem(String operatingSystem) {
    return RuntimePlatform._(
      switch (operatingSystem.toLowerCase()) {
        'android' => RuntimePlatformKind.android,
        'ios' => RuntimePlatformKind.ios,
        'ohos' => RuntimePlatformKind.ohos,
        'windows' => RuntimePlatformKind.windows,
        'macos' => RuntimePlatformKind.macos,
        'linux' => RuntimePlatformKind.linux,
        _ => RuntimePlatformKind.other,
      },
    );
  }

  final RuntimePlatformKind kind;

  bool get isAndroid => kind == RuntimePlatformKind.android;
  bool get isIOS => kind == RuntimePlatformKind.ios;
  bool get isOhos => kind == RuntimePlatformKind.ohos;
  bool get isWindows => kind == RuntimePlatformKind.windows;
  bool get isMacOS => kind == RuntimePlatformKind.macos;
  bool get isLinux => kind == RuntimePlatformKind.linux;

  bool get isMobile => isAndroid || isIOS || isOhos;
  bool get isDesktop => isWindows || isMacOS || isLinux;

  bool get supportsDesktopWindow => isDesktop;
  bool get supportsMpvBackend => isDesktop || isAndroid;
  bool get supportsSqfliteFfi => isWindows || isLinux;
  bool get supportsSmtc => isWindows;
  bool get supportsAudioSessionConfiguration => isMobile;
  bool get usesDesktopStoragePaths => isDesktop;
}

final RuntimePlatform runtimePlatform =
    RuntimePlatform.fromOperatingSystem(Platform.operatingSystem);
