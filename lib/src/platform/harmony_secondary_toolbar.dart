import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'harmony_channel.dart';

enum HarmonySecondaryToolbarLayout { menu, actions, search }

@immutable
class HarmonySecondaryToolbarData {
  const HarmonySecondaryToolbarData({
    this.layout = HarmonySecondaryToolbarLayout.actions,
    this.modeLabels = const [],
    this.modeIcons = const [],
    this.modeActions = const [],
    this.modeSelected = const [],
    this.modeEnabled = const [],
    this.selectedMode = 0,
    this.title = '',
    this.inputValue = '',
    this.inputHint = '',
    this.inputAction = '',
    this.toolIcons = const [],
    this.toolActions = const [],
    this.toolSelected = const [],
    this.toolEnabled = const [],
  });

  final HarmonySecondaryToolbarLayout layout;
  final List<String> modeLabels;
  final List<String> modeIcons;
  final List<String> modeActions;
  final List<bool> modeSelected;
  final List<bool> modeEnabled;
  final int selectedMode;
  final String title;
  final String inputValue;
  final String inputHint;
  final String inputAction;
  final List<String> toolIcons;
  final List<String> toolActions;
  final List<bool> toolSelected;
  final List<bool> toolEnabled;

  @override
  bool operator ==(Object other) =>
      other is HarmonySecondaryToolbarData &&
      other.layout == layout &&
      listEquals(other.modeLabels, modeLabels) &&
      listEquals(other.modeIcons, modeIcons) &&
      listEquals(other.modeActions, modeActions) &&
      listEquals(other.modeSelected, modeSelected) &&
      listEquals(other.modeEnabled, modeEnabled) &&
      other.selectedMode == selectedMode &&
      other.title == title &&
      other.inputValue == inputValue &&
      other.inputHint == inputHint &&
      other.inputAction == inputAction &&
      listEquals(other.toolIcons, toolIcons) &&
      listEquals(other.toolActions, toolActions) &&
      listEquals(other.toolSelected, toolSelected) &&
      listEquals(other.toolEnabled, toolEnabled);

  @override
  int get hashCode => Object.hashAll([
    layout,
    Object.hashAll(modeLabels),
    Object.hashAll(modeIcons),
    Object.hashAll(modeActions),
    Object.hashAll(modeSelected),
    Object.hashAll(modeEnabled),
    selectedMode,
    title,
    inputValue,
    inputHint,
    inputAction,
    Object.hashAll(toolIcons),
    Object.hashAll(toolActions),
    Object.hashAll(toolSelected),
    Object.hashAll(toolEnabled),
  ]);
}

typedef HarmonySecondaryToolbarActionHandler =
    void Function(HarmonyNativeTopAction action);

/// Keeps a child page's dynamic toolbar state and actions out of [MyScreen].
///
/// Publishing is deferred until the end of the frame because child pages often
/// derive their toolbar state while building a stream-backed collection.
final class HarmonySecondaryToolbarController extends ChangeNotifier {
  HarmonySecondaryToolbarController(this._value);

  HarmonySecondaryToolbarData _value;
  HarmonySecondaryToolbarData? _pendingValue;
  bool _publishScheduled = false;
  Object? _actionOwner;
  HarmonySecondaryToolbarActionHandler? _actionHandler;

  HarmonySecondaryToolbarData get value => _value;

  void publish(HarmonySecondaryToolbarData value) {
    if (value == _pendingValue || (_pendingValue == null && value == _value)) {
      return;
    }
    _pendingValue = value;
    if (_publishScheduled) return;
    _publishScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _publishScheduled = false;
      final pendingValue = _pendingValue;
      _pendingValue = null;
      if (pendingValue == null || pendingValue == _value) return;
      _value = pendingValue;
      notifyListeners();
    });
  }

  void attachActionHandler(
    Object owner,
    HarmonySecondaryToolbarActionHandler handler,
  ) {
    _actionOwner = owner;
    _actionHandler = handler;
  }

  void detachActionHandler(Object owner) {
    if (!identical(_actionOwner, owner)) return;
    _actionOwner = null;
    _actionHandler = null;
  }

  bool dispatch(HarmonyNativeTopAction action) {
    final handler = _actionHandler;
    if (handler == null) return false;
    handler(action);
    return true;
  }
}
