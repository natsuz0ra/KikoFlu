import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, ColorScheme;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;

import 'runtime_platform.dart';

class HarmonyShellCapabilities {
  const HarmonyShellCapabilities({
    required this.bottomBar,
    required this.topBar,
    required this.bottomExtent,
  });

  final bool bottomBar;
  final bool topBar;
  final double bottomExtent;
}

enum HarmonyTopBarPage { works, search, searchResult, my }

typedef HarmonyShellColors = ({
  bool isDark,
  String badge,
  String selected,
  String selectedContainer,
  String unselected,
  String topMaskStrong,
  String topMaskWeak,
});

HarmonyShellColors harmonyShellColorsFromColorScheme(ColorScheme colors) => (
  isDark: colors.brightness == Brightness.dark,
  badge: _argbHex(colors.error),
  selected: _argbHex(colors.primary),
  selectedContainer: _argbHex(colors.primary.withValues(alpha: 0.14)),
  unselected: _argbHex(colors.onSurfaceVariant),
  // Keep the system material transparent so its dark-mode light feedback is
  // preserved; only the static full-width tint follows the theme.
  topMaskStrong: _argbHex(
    colors.brightness == Brightness.dark
        ? const Color(0x4216171b)
        : colors.surface.withValues(alpha: 0.82),
  ),
  topMaskWeak: _argbHex(
    colors.brightness == Brightness.dark
        ? const Color(0x1016171b)
        : colors.surface.withValues(alpha: 0.12),
  ),
);

extension HarmonyShellColorsSignature on HarmonyShellColors {
  String get signature => <String>[
    isDark.toString(),
    badge,
    selected,
    selectedContainer,
    unselected,
    topMaskStrong,
    topMaskWeak,
  ].join('|');
}

String _argbHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';

@immutable
class HarmonyNativeTopAction {
  const HarmonyNativeTopAction({
    required this.page,
    required this.action,
    this.value,
  });

  final HarmonyTopBarPage page;
  final String action;
  final String? value;
}

typedef HarmonyNativeTopActionHandler =
    void Function(HarmonyNativeTopAction action);

final class HarmonyNativeTopActionRegistration {
  HarmonyNativeTopActionRegistration._(this.page, this.handler);

  final HarmonyTopBarPage page;
  final HarmonyNativeTopActionHandler handler;
  bool _active = true;

  void dispose() {
    if (!_active) return;
    _active = false;
    HarmonyChannel.clearNativeTopActionHandler(this);
  }
}

@immutable
class _HarmonyTopBarData {
  const _HarmonyTopBarData({
    required this.page,
    required this.title,
    required this.leadingIcon,
    required this.leadingAction,
    required this.modeLabels,
    required this.modeIcons,
    required this.modeActions,
    required this.selectedMode,
    required this.toolIcons,
    required this.toolActions,
    required this.toolSelected,
    required this.toolEnabled,
    required this.secondaryModeLabels,
    required this.secondaryModeIcons,
    required this.secondaryModeActions,
    required this.secondaryModeSelected,
    required this.secondaryModeEnabled,
    required this.secondarySelectedMode,
    required this.secondaryLayout,
    required this.secondaryTitle,
    required this.secondaryInputValue,
    required this.secondaryInputHint,
    required this.secondaryInputAction,
    required this.secondaryToolIcons,
    required this.secondaryToolActions,
    required this.secondaryToolSelected,
    required this.secondaryToolEnabled,
    required this.secondaryVisible,
    required this.collapsed,
    required this.colors,
  });

  final HarmonyTopBarPage page;
  final String title;
  final String leadingIcon;
  final String leadingAction;
  final List<String> modeLabels;
  final List<String> modeIcons;
  final List<String> modeActions;
  final int selectedMode;
  final List<String> toolIcons;
  final List<String> toolActions;
  final List<bool> toolSelected;
  final List<bool> toolEnabled;
  final List<String> secondaryModeLabels;
  final List<String> secondaryModeIcons;
  final List<String> secondaryModeActions;
  final List<bool> secondaryModeSelected;
  final List<bool> secondaryModeEnabled;
  final int secondarySelectedMode;
  final String secondaryLayout;
  final String secondaryTitle;
  final String secondaryInputValue;
  final String secondaryInputHint;
  final String secondaryInputAction;
  final List<String> secondaryToolIcons;
  final List<String> secondaryToolActions;
  final List<bool> secondaryToolSelected;
  final List<bool> secondaryToolEnabled;
  final bool secondaryVisible;
  final bool collapsed;
  final HarmonyShellColors colors;

  Map<String, Object?> toArguments() => <String, Object?>{
    'topBarPage': page.name,
    'topTitle': title,
    'leadingIcon': leadingIcon,
    'leadingAction': leadingAction,
    'modeLabels': modeLabels,
    'modeIcons': modeIcons,
    'modeActions': modeActions,
    'selectedMode': selectedMode,
    'toolIcons': toolIcons,
    'toolActions': toolActions,
    'toolSelected': toolSelected,
    'toolEnabled': toolEnabled,
    'secondaryModeLabels': secondaryModeLabels,
    'secondaryModeIcons': secondaryModeIcons,
    'secondaryModeActions': secondaryModeActions,
    'secondaryModeSelected': secondaryModeSelected,
    'secondaryModeEnabled': secondaryModeEnabled,
    'secondarySelectedMode': secondarySelectedMode,
    'secondaryLayout': secondaryLayout,
    'secondaryTitle': secondaryTitle,
    'secondaryInputValue': secondaryInputValue,
    'secondaryInputHint': secondaryInputHint,
    'secondaryInputAction': secondaryInputAction,
    'secondaryToolIcons': secondaryToolIcons,
    'secondaryToolActions': secondaryToolActions,
    'secondaryToolSelected': secondaryToolSelected,
    'secondaryToolEnabled': secondaryToolEnabled,
    'secondaryVisible': secondaryVisible,
    'topCollapsed': collapsed,
    'selectedColor': colors.selected,
    'selectedContainerColor': colors.selectedContainer,
    'unselectedColor': colors.unselected,
    'isDark': colors.isDark,
    'topMaskStrongColor': colors.topMaskStrong,
    'topMaskWeakColor': colors.topMaskWeak,
  };

  @override
  bool operator ==(Object other) {
    return other is _HarmonyTopBarData &&
        other.page == page &&
        other.title == title &&
        other.leadingIcon == leadingIcon &&
        other.leadingAction == leadingAction &&
        listEquals(other.modeLabels, modeLabels) &&
        listEquals(other.modeIcons, modeIcons) &&
        listEquals(other.modeActions, modeActions) &&
        other.selectedMode == selectedMode &&
        listEquals(other.toolIcons, toolIcons) &&
        listEquals(other.toolActions, toolActions) &&
        listEquals(other.toolSelected, toolSelected) &&
        listEquals(other.toolEnabled, toolEnabled) &&
        listEquals(other.secondaryModeLabels, secondaryModeLabels) &&
        listEquals(other.secondaryModeIcons, secondaryModeIcons) &&
        listEquals(other.secondaryModeActions, secondaryModeActions) &&
        listEquals(other.secondaryModeSelected, secondaryModeSelected) &&
        listEquals(other.secondaryModeEnabled, secondaryModeEnabled) &&
        other.secondarySelectedMode == secondarySelectedMode &&
        other.secondaryLayout == secondaryLayout &&
        other.secondaryTitle == secondaryTitle &&
        other.secondaryInputValue == secondaryInputValue &&
        other.secondaryInputHint == secondaryInputHint &&
        other.secondaryInputAction == secondaryInputAction &&
        listEquals(other.secondaryToolIcons, secondaryToolIcons) &&
        listEquals(other.secondaryToolActions, secondaryToolActions) &&
        listEquals(other.secondaryToolSelected, secondaryToolSelected) &&
        listEquals(other.secondaryToolEnabled, secondaryToolEnabled) &&
        other.secondaryVisible == secondaryVisible &&
        other.collapsed == collapsed &&
        other.colors == colors;
  }

  @override
  int get hashCode => Object.hashAll([
    page,
    title,
    leadingIcon,
    leadingAction,
    Object.hashAll(modeLabels),
    Object.hashAll(modeIcons),
    Object.hashAll(modeActions),
    selectedMode,
    Object.hashAll(toolIcons),
    Object.hashAll(toolActions),
    Object.hashAll(toolSelected),
    Object.hashAll(toolEnabled),
    Object.hashAll(secondaryModeLabels),
    Object.hashAll(secondaryModeIcons),
    Object.hashAll(secondaryModeActions),
    Object.hashAll(secondaryModeSelected),
    Object.hashAll(secondaryModeEnabled),
    secondarySelectedMode,
    secondaryLayout,
    secondaryTitle,
    secondaryInputValue,
    secondaryInputHint,
    secondaryInputAction,
    Object.hashAll(secondaryToolIcons),
    Object.hashAll(secondaryToolActions),
    Object.hashAll(secondaryToolSelected),
    Object.hashAll(secondaryToolEnabled),
    secondaryVisible,
    collapsed,
    colors,
  ]);
}

/// Flutter 与 ArkUI 沉浸光感外壳之间的唯一通道契约。
abstract final class HarmonyChannel {
  static const MethodChannel _channel = MethodChannel('harmonyChannel');
  static bool _initialized = false;
  static final Map<HarmonyTopBarPage, _HarmonyTopBarData> _topBarData = {};
  static HarmonyTopBarPage? _activeTopBarPage;
  static _HarmonyTopBarData? _sentTopBarData;
  static Future<bool>? _topBarDataSync;
  static bool _desiredShellSuppressed = false;
  static bool? _confirmedShellSuppressed;
  static Future<bool>? _shellSuppressionSync;
  static final ValueNotifier<int> nativeTopDataRevision = ValueNotifier(0);
  static final Map<HarmonyTopBarPage, HarmonyNativeTopActionHandler>
  _topActionHandlers = {};

  static void Function(int index)? onNativeTabSelected;

  /// 只有原生能力握手及显隐调用均成功后才为 true。
  static final ValueNotifier<bool> nativeTopBarActive = ValueNotifier(false);
  static final ValueNotifier<bool> nativeBottomBarActive = ValueNotifier(false);
  static final ValueNotifier<double> nativeBottomExtent = ValueNotifier(68);

  static void initialize() {
    if (!runtimePlatform.isOhos || _initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      final arguments = call.arguments;
      final map = arguments is Map ? arguments : const <Object?, Object?>{};
      switch (call.method) {
        case 'onNativeTabSelected':
          final index = map['index'];
          if (index is int) onNativeTabSelected?.call(index);
          break;
        case 'onNativeTopAction':
          final pageName = map['page'];
          final action = map['action'];
          final value = map['value'];
          final page = HarmonyTopBarPage.values
              .where((candidate) => candidate.name == pageName)
              .firstOrNull;
          if (page != null && action is String) {
            _dispatchNativeTopAction(
              page,
              HarmonyNativeTopAction(
                page: page,
                action: action,
                value: value is String ? value : null,
              ),
            );
          }
          break;
        case 'onNativeBottomMetrics':
          final extent = map['extent'];
          if (extent is num && extent > 0) {
            nativeBottomExtent.value = extent.toDouble();
          }
          break;
      }
    });
  }

  static Future<HarmonyShellCapabilities?> getCapabilities() async {
    if (!runtimePlatform.isOhos) return null;
    initialize();
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'getNativeShellCapabilities',
      );
      if (result == null) return null;
      final extent = (result['bottomExtent'] as num?)?.toDouble() ?? 68;
      nativeBottomExtent.value = extent;
      return HarmonyShellCapabilities(
        bottomBar: result['bottomBar'] == true,
        topBar: result['topBar'] == true,
        bottomExtent: extent,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> setNativeTopBar(bool enabled) =>
      _invokeBool('setShellTopBar', {'useNativeTopBar': enabled});

  static Future<bool> setNativeBottomBar(bool enabled) =>
      _invokeBool('setShellBars', {'useNativeTabs': enabled});

  static Future<bool> setNativeTabIndex(int index) =>
      _invokeBool('setNativeTabIndex', {'index': index});

  static Future<bool> setNativeBottomBarData({
    required List<String> labels,
    required bool showUpdateBadge,
    required String badgeColor,
    required String selectedColor,
    required String unselectedColor,
  }) => _invokeBool('setNativeBottomBarData', {
    'labels': labels,
    'showUpdateBadge': showUpdateBadge,
    'badgeColor': badgeColor,
    'selectedColor': selectedColor,
    'unselectedColor': unselectedColor,
  });

  static bool isNativeTopBarActiveFor(HarmonyTopBarPage page) =>
      nativeTopBarActive.value && _activeTopBarPage == page;

  static HarmonyNativeTopActionRegistration setNativeTopActionHandler(
    HarmonyTopBarPage page,
    HarmonyNativeTopActionHandler handler,
  ) {
    _topActionHandlers[page] = handler;
    return HarmonyNativeTopActionRegistration._(page, handler);
  }

  static void clearNativeTopActionHandler(
    HarmonyNativeTopActionRegistration registration,
  ) {
    if (_topActionHandlers[registration.page] == registration.handler) {
      _topActionHandlers.remove(registration.page);
    }
  }

  static void _dispatchNativeTopAction(
    HarmonyTopBarPage page,
    HarmonyNativeTopAction action,
  ) {
    final handler = _topActionHandlers[page];
    if (handler != null) {
      handler(action);
      return;
    }
    var retries = 3;
    void retry() {
      final current = _topActionHandlers[page];
      if (current != null) {
        current(action);
      } else if (retries-- > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => retry());
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => retry());
  }

  /// Synchronously stages the latest toolbar state for one main tab.
  ///
  /// Initial native takeover flushes this snapshot before making ArkUI
  /// visible. While the native toolbar is active, changed snapshots are
  /// serialized and coalesced so an older MethodChannel completion cannot
  /// overwrite a newer theme, locale, or toolbar selection.
  static void stageNativeTopBarData({
    required HarmonyTopBarPage page,
    String title = '',
    String leadingIcon = '',
    String leadingAction = '',
    required List<String> modeLabels,
    required List<String> modeIcons,
    required List<String> modeActions,
    required int selectedMode,
    required List<String> toolIcons,
    required List<String> toolActions,
    required List<bool> toolSelected,
    required List<bool> toolEnabled,
    List<String> secondaryModeLabels = const [],
    List<String> secondaryModeIcons = const [],
    List<String> secondaryModeActions = const [],
    List<bool> secondaryModeSelected = const [],
    List<bool> secondaryModeEnabled = const [],
    int secondarySelectedMode = 0,
    String secondaryLayout = 'menu',
    String secondaryTitle = '',
    String secondaryInputValue = '',
    String secondaryInputHint = '',
    String secondaryInputAction = '',
    List<String> secondaryToolIcons = const [],
    List<String> secondaryToolActions = const [],
    List<bool> secondaryToolSelected = const [],
    List<bool> secondaryToolEnabled = const [],
    bool secondaryVisible = false,
    bool collapsed = false,
    required HarmonyShellColors colors,
  }) {
    assert(modeLabels.length == modeIcons.length);
    assert(modeLabels.length == modeActions.length);
    assert(toolIcons.length == toolActions.length);
    assert(toolIcons.length == toolSelected.length);
    assert(toolIcons.length == toolEnabled.length);
    assert(secondaryModeLabels.length == secondaryModeIcons.length);
    assert(secondaryModeLabels.length == secondaryModeActions.length);
    assert(
      secondaryModeSelected.isEmpty ||
          secondaryModeIcons.length == secondaryModeSelected.length,
    );
    assert(
      secondaryModeEnabled.isEmpty ||
          secondaryModeIcons.length == secondaryModeEnabled.length,
    );
    assert(secondaryToolIcons.length == secondaryToolActions.length);
    assert(secondaryToolIcons.length == secondaryToolSelected.length);
    assert(secondaryToolIcons.length == secondaryToolEnabled.length);
    final data = _HarmonyTopBarData(
      page: page,
      title: title,
      leadingIcon: leadingIcon,
      leadingAction: leadingAction,
      modeLabels: List.unmodifiable(modeLabels),
      modeIcons: List.unmodifiable(modeIcons),
      modeActions: List.unmodifiable(modeActions),
      selectedMode: selectedMode,
      toolIcons: List.unmodifiable(toolIcons),
      toolActions: List.unmodifiable(toolActions),
      toolSelected: List.unmodifiable(toolSelected),
      toolEnabled: List.unmodifiable(toolEnabled),
      secondaryModeLabels: List.unmodifiable(secondaryModeLabels),
      secondaryModeIcons: List.unmodifiable(secondaryModeIcons),
      secondaryModeActions: List.unmodifiable(secondaryModeActions),
      secondaryModeSelected: List.unmodifiable(secondaryModeSelected),
      secondaryModeEnabled: List.unmodifiable(secondaryModeEnabled),
      secondarySelectedMode: secondarySelectedMode,
      secondaryLayout: secondaryLayout,
      secondaryTitle: secondaryTitle,
      secondaryInputValue: secondaryInputValue,
      secondaryInputHint: secondaryInputHint,
      secondaryInputAction: secondaryInputAction,
      secondaryToolIcons: List.unmodifiable(secondaryToolIcons),
      secondaryToolActions: List.unmodifiable(secondaryToolActions),
      secondaryToolSelected: List.unmodifiable(secondaryToolSelected),
      secondaryToolEnabled: List.unmodifiable(secondaryToolEnabled),
      secondaryVisible: secondaryVisible,
      collapsed: collapsed,
      colors: colors,
    );
    if (_topBarData[page] == data) return;
    _topBarData[page] = data;
    nativeTopDataRevision.value++;
    if (isNativeTopBarActiveFor(page)) {
      unawaited(_syncActiveNativeTopBarData());
    }
  }

  /// Flushes top-bar data, shows ArkUI, and verifies that no newer staged
  /// snapshot arrived during the visibility call. Flutter must only hide its
  /// fallback after this entire operation returns true.
  static Future<bool> activateNativeTopBar(HarmonyTopBarPage page) async {
    if (_activeTopBarPage != page) {
      nativeTopBarActive.value = false;
      _activeTopBarPage = page;
    }
    if (!await _syncLatestNativeTopBarData()) return false;
    if (!await setNativeTopBar(true)) return false;
    if (await _syncLatestNativeTopBarData()) return true;
    await setNativeTopBar(false);
    return false;
  }

  static void deactivateNativeTopBar() {
    _activeTopBarPage = null;
    nativeTopBarActive.value = false;
  }

  static Future<void> _syncActiveNativeTopBarData() async {
    final ready = await _syncLatestNativeTopBarData();
    if (ready || !nativeTopBarActive.value) return;
    nativeTopBarActive.value = false;
    await setNativeTopBar(false);
  }

  static Future<bool> _syncLatestNativeTopBarData() {
    final inFlight = _topBarDataSync;
    if (inFlight != null) return inFlight;
    final future = _drainNativeTopBarData();
    _topBarDataSync = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_topBarDataSync, future)) {
          _topBarDataSync = null;
        }
      }),
    );
    return future;
  }

  static Future<bool> _drainNativeTopBarData() async {
    while (true) {
      final activePage = _activeTopBarPage;
      if (activePage == null) return false;
      final data = _topBarData[activePage];
      if (data == null) return false;
      if (_sentTopBarData == data) return true;
      if (!await _invokeBool('setNativeTopBarData', data.toArguments())) {
        return false;
      }
      _sentTopBarData = data;
      if (_activeTopBarPage == activePage && _topBarData[activePage] == data) {
        return true;
      }
    }
  }

  static Future<bool> setNativeBarsHidden(bool hidden) =>
      _invokeBool('setShellBarsHidden', {'hidden': hidden});

  /// Temporarily hides only the ArkUI shell siblings above FlutterPage.
  ///
  /// This deliberately leaves the confirmed native-active flags untouched so
  /// Flutter does not render its fallback bars while a Flutter dialog is open.
  static Future<bool> setNativeShellSuppressed(bool suppressed) {
    if (!runtimePlatform.isOhos) return Future.value(false);
    _desiredShellSuppressed = suppressed;
    final inFlight = _shellSuppressionSync;
    if (inFlight != null) {
      return inFlight.then((success) {
        if (_confirmedShellSuppressed == _desiredShellSuppressed) {
          return success;
        }
        if (identical(_shellSuppressionSync, inFlight)) {
          _shellSuppressionSync = null;
        }
        return setNativeShellSuppressed(_desiredShellSuppressed);
      });
    }
    if (_confirmedShellSuppressed == suppressed) return Future.value(true);

    final future = _drainShellSuppression();
    _shellSuppressionSync = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_shellSuppressionSync, future)) {
          _shellSuppressionSync = null;
        }
      }),
    );
    return future;
  }

  static Future<bool> _drainShellSuppression() async {
    while (true) {
      final target = _desiredShellSuppressed;
      if (_confirmedShellSuppressed != target) {
        final success = await _invokeBool('setNativeShellSuppressed', {
          'suppressed': target,
        });
        if (!success) return false;
        _confirmedShellSuppressed = target;
      }
      if (_desiredShellSuppressed == target) return true;
    }
  }

  static Future<bool> _invokeBool(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!runtimePlatform.isOhos) return false;
    try {
      return await _channel.invokeMethod<bool>(method, arguments) == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
