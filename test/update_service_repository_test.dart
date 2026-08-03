import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/update_service.dart';

void main() {
  test('update checks and release links use the HarmonyOS fork', () {
    expect(
      UpdateService.githubApiUrl,
      'https://api.github.com/repos/natsuz0ra/KikoFlu/releases/latest',
    );
    expect(
      UpdateService.releasePageUrl,
      'https://github.com/natsuz0ra/KikoFlu/releases/latest',
    );
  });
}
