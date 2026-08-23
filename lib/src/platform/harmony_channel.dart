import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

@immutable
class HarmonyNativeTopAction {
  const HarmonyNativeTopAction({required this.page, required this.action});

  final HarmonyTopBarPage page;
  final String action;
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
    required this.secondarySelectedMode,
    required this.secondaryToolIcons,
    required this.secondaryToolActions,
    required this.secondaryToolSelected,
    required this.secondaryToolEnabled,
    required this.secondaryVisible,
    required this.collapsed,
    required this.selectedColor,
    required this.selectedContainerColor,
    required this.unselectedColor,
    required this.topMaskStrongColor,
    required this.topMaskWeakColor,
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
  final int secondarySelectedMode;
  final List<String> secondaryToolIcons;
  final List<String> secondaryToolActions;
  final List<bool> secondaryToolSelected;
  final List<bool> secondaryToolEnabled;
  final bool secondaryVisible;
  final bool collapsed;
  final String selectedColor;
  final String selectedContainerColor;
  final String unselectedColor;
  final String topMaskStrongColor;
  final String topMaskWeakColor;

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
    'secondarySelectedMode': secondarySelectedMode,
    'secondaryToolIcons': secondaryToolIcons,
    'secondaryToolActions': secondaryToolActions,
    'secondaryToolSelected': secondaryToolSelected,
    'secondaryToolEnabled': secondaryToolEnabled,
    'secondaryVisible': secondaryVisible,
    'topCollapsed': collapsed,
    'selectedColor': selectedColor,
    'selectedContainerColor': selectedContainerColor,
    'unselectedColor': unselectedColor,
    'topMaskStrongColor': topMaskStrongColor,
    'topMaskWeakColor': topMaskWeakColor,
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
        other.secondarySelectedMode == secondarySelectedMode &&
        listEquals(other.secondaryToolIcons, secondaryToolIcons) &&
        listEquals(other.secondaryToolActions, secondaryToolActions) &&
        listEquals(other.secondaryToolSelected, secondaryToolSelected) &&
        listEquals(other.secondaryToolEnabled, secondaryToolEnabled) &&
        other.secondaryVisible == secondaryVisible &&
        other.collapsed == collapsed &&
        other.selectedColor == selectedColor &&
        other.selectedContainerColor == selectedContainerColor &&
        other.unselectedColor == unselectedColor &&
        other.topMaskStrongColor == topMaskStrongColor &&
        other.topMaskWeakColor == topMaskWeakColor;
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
    secondarySelectedMode,
    Object.hashAll(secondaryToolIcons),
    Object.hashAll(secondaryToolActions),
    Object.hashAll(secondaryToolSelected),
    Object.hashAll(secondaryToolEnabled),
    secondaryVisible,
    collapsed,
    selectedColor,
    selectedContainerColor,
    unselectedColor,
    topMaskStrongColor,
    topMaskWeakColor,
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
  static final Map<
    HarmonyTopBarPage,
    void Function(HarmonyNativeTopAction action)
  >
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
          final page = HarmonyTopBarPage.values
              .where((candidate) => candidate.name == pageName)
              .firstOrNull;
          if (page != null && action is String) {
            _topActionHandlers[page]?.call(
              HarmonyNativeTopAction(page: page, action: action),
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

  static void setNativeTopActionHandler(
    HarmonyTopBarPage page,
    void Function(HarmonyNativeTopAction action)? handler,
  ) {
    if (handler == null) {
      _topActionHandlers.remove(page);
    } else {
      _topActionHandlers[page] = handler;
    }
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
    int secondarySelectedMode = 0,
    List<String> secondaryToolIcons = const [],
    List<String> secondaryToolActions = const [],
    List<bool> secondaryToolSelected = const [],
    List<bool> secondaryToolEnabled = const [],
    bool secondaryVisible = false,
    bool collapsed = false,
    required String selectedColor,
    required String selectedContainerColor,
    required String unselectedColor,
    required String topMaskStrongColor,
    required String topMaskWeakColor,
  }) {
    assert(modeLabels.length == modeIcons.length);
    assert(modeLabels.length == modeActions.length);
    assert(toolIcons.length == toolActions.length);
    assert(toolIcons.length == toolSelected.length);
    assert(toolIcons.length == toolEnabled.length);
    assert(secondaryModeLabels.length == secondaryModeIcons.length);
    assert(secondaryModeLabels.length == secondaryModeActions.length);
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
      secondarySelectedMode: secondarySelectedMode,
      secondaryToolIcons: List.unmodifiable(secondaryToolIcons),
      secondaryToolActions: List.unmodifiable(secondaryToolActions),
      secondaryToolSelected: List.unmodifiable(secondaryToolSelected),
      secondaryToolEnabled: List.unmodifiable(secondaryToolEnabled),
      secondaryVisible: secondaryVisible,
      collapsed: collapsed,
      selectedColor: selectedColor,
      selectedContainerColor: selectedContainerColor,
      unselectedColor: unselectedColor,
      topMaskStrongColor: topMaskStrongColor,
      topMaskWeakColor: topMaskWeakColor,
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
