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
}
