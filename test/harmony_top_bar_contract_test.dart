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
}
