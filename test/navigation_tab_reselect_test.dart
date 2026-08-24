import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/navigation_tab_reselect.dart';

void main() {
  testWidgets('shared reselect controller only resets the visible tab', (
    tester,
  ) async {
    final reselectController = NavigationTabReselectController();
    final selectedIndex = ValueNotifier(0);
    final firstScrollController = ScrollController(initialScrollOffset: 300);
    final secondScrollController = ScrollController(initialScrollOffset: 300);
    addTearDown(reselectController.dispose);
    addTearDown(selectedIndex.dispose);
    addTearDown(firstScrollController.dispose);
    addTearDown(secondScrollController.dispose);

    Widget page(ScrollController scrollController) {
      return ListView.builder(
        controller: scrollController,
        itemExtent: 80,
        itemCount: 30,
        itemBuilder: (context, index) => Text('Item $index'),
      ).onNavigationTabReselect(
        controller: reselectController,
        onReselect: () => scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: selectedIndex,
          builder: (context, index, child) => IndexedStack(
            index: index,
            children: [
              page(firstScrollController),
              page(secondScrollController),
            ],
          ),
        ),
      ),
    );

    expect(firstScrollController.offset, 300);
    expect(secondScrollController.offset, 300);

    reselectController.reselect();
    await tester.pumpAndSettle();

    expect(firstScrollController.offset, 0);
    expect(secondScrollController.offset, 300);

    selectedIndex.value = 1;
    await tester.pump();
    reselectController.reselect();
    await tester.pumpAndSettle();

    expect(secondScrollController.offset, 0);
  });
}
