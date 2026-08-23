import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/platform/harmony_channel.dart';

void main() {
  test('keeps native top actions scoped to their owning page', () {
    const action = HarmonyNativeTopAction(
      page: HarmonyTopBarPage.works,
      action: 'sort',
    );

    expect(action.page, HarmonyTopBarPage.works);
    expect(action.action, 'sort');
  });

  test('projects shared Flutter colors into the native shell contract', () {
    final colors = harmonyShellColorsFromColorScheme(
      ColorScheme.fromSeed(seedColor: const Color(0xff1677ff)),
    );

    expect(colors.selected, startsWith('#ff'));
    expect(colors.selectedContainer, startsWith('#24'));
    expect(colors.topMaskStrong, startsWith('#d1'));
    expect(colors.topMaskWeak, startsWith('#1f'));
    expect(
      colors,
      harmonyShellColorsFromColorScheme(
        ColorScheme.fromSeed(seedColor: const Color(0xff1677ff)),
      ),
    );
  });

  test('routes every native top action through the attached channel', () {
    final plugin = File(
      'ohos/entry/src/main/ets/plugins/HarmonyChannel.ets',
    ).readAsStringSync();
    final topBar = File(
      'ohos/entry/src/main/ets/immersive/ImmersiveTopBar.ets',
    ).readAsStringSync();
    final ability = File(
      'ohos/entry/src/main/ets/entryability/EntryAbility.ets',
    ).readAsStringSync();

    expect(plugin, contains('const attachedChannels: MethodChannel[] = [];'));
    expect(plugin, contains('function latestAttachedChannel()'));
    expect(plugin, contains('export function invokeNativeTopAction('));
    expect(plugin, contains("channel.invokeMethod('onNativeTopAction'"));
    expect(plugin, contains('attachedChannels.push(this.channel);'));
    expect(plugin, contains('attachedChannels.indexOf(channel)'));
    expect(plugin, contains('attachedChannels.splice(index, 1);'));
    expect(plugin, contains("action === ''"));
    expect(topBar, contains("import { invokeNativeTopAction }"));
    expect(topBar, contains('invokeNativeTopAction(this.topBarPage, action);'));
    expect(topBar, contains('this.emit(this.topLeadingAction)'));
    expect(topBar, contains('this.emit(this.topModeActions[index])'));
    expect(topBar, contains('this.runToolAction(this.topToolActions[index])'));
    expect(topBar, contains('this.emit(action);'));
    expect(
      topBar,
      contains('this.runToolAction(this.secondaryToolActions[index])'),
    );
    expect(topBar, isNot(contains('.eventHub.emit(')));
    expect(ability, isNot(contains('EVENT_NATIVE_TOP_ACTION')));
    expect(ability, isNot(contains('nativeTopActionCallback')));
  });

  test('keeps all Flutter top action owners and actions registered', () {
    const owners = <String, ({String page, List<String> actions})>{
      'lib/src/screens/works_screen.dart': (
        page: 'HarmonyTopBarPage.works',
        actions: [
          'mode_all',
          'mode_popular',
          'mode_recommended',
          'layout',
          'subtitle',
          'sort',
        ],
      ),
      'lib/src/screens/search_screen.dart': (
        page: 'HarmonyTopBarPage.search',
        actions: ['toggle_filter'],
      ),
      'lib/src/screens/search_result_screen.dart': (
        page: 'HarmonyTopBarPage.searchResult',
        actions: ['back', 'layout', 'subtitle', 'sort'],
      ),
      'lib/src/screens/my_screen.dart': (
        page: 'HarmonyTopBarPage.my',
        actions: ['tab_', 'filter_', 'layout', 'subtitle', 'sort'],
      ),
    };

    for (final entry in owners.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(source, contains('setNativeTopActionHandler('));
      expect(source, contains(entry.value.page));
      expect(source, contains('_handleNativeTopAction'));
      for (final action in entry.value.actions) {
        expect(source, contains("'$action"));
      }
    }
  });
}
