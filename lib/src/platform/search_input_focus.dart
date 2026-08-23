import 'package:flutter/foundation.dart';

/// Explicit search-input focus state for the main shell.
///
/// HarmonyOS does not always propagate IME viewInsets through the parent
/// FlutterPage, so MainScreen cannot rely on MediaQuery alone.
final ValueNotifier<bool> searchInputFocused = ValueNotifier<bool>(false);
