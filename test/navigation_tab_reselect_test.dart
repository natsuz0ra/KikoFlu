import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/navigation_tab_reselect.dart';

void main() {
  testWidgets('only the visible indexed page handles a tab reselect',
      (tester) async {
    final controller = NavigationTabReselectController();
    var selectedIndex = 0;
    var firstCalls = 0;
    var secondCalls = 0;
    late StateSetter setState;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, updateState) {
            setState = updateState;
            return Scaffold(
              body: IndexedStack(
                index: selectedIndex,
                children: [
                  NavigationTabReselectListener(
                    controller: controller,
                    onReselect: () => firstCalls++,
                    child: const SizedBox.expand(child: Text('First')),
                  ),
                  NavigationTabReselectListener(
                    controller: controller,
                    onReselect: () => secondCalls++,
                    child: const SizedBox.expand(child: Text('Second')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    controller.reselect();
    expect(firstCalls, 1);
    expect(secondCalls, 0);

    setState(() => selectedIndex = 1);
    await tester.pump();
    controller.reselect();

    expect(firstCalls, 1);
    expect(secondCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
