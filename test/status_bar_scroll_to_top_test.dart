import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/status_bar_scroll_to_top.dart';

void main() {
  testWidgets('status bar tap only scrolls the foreground page',
      (tester) async {
    final backgroundController = ScrollController(initialScrollOffset: 500);
    final foregroundController = ScrollController(initialScrollOffset: 500);

    Widget buildPage(ScrollController controller) {
      return StatusBarScrollToTop(
        controller: controller,
        child: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (context, index) => SizedBox(
              height: 50,
              child: Text('Item $index'),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute(
            builder: (context) => buildPage(backgroundController),
          ),
          MaterialPageRoute(
            builder: (context) => buildPage(foregroundController),
          ),
        ],
        onGenerateRoute: (_) => throw UnimplementedError(),
      ),
    );

    tester.simulateStatusBarTap();
    await tester.pumpAndSettle();

    expect(backgroundController.offset, 500);
    expect(foregroundController.offset, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    backgroundController.dispose();
    foregroundController.dispose();
  });

  testWidgets('status bar tap leaves hidden indexed scroll views unchanged',
      (tester) async {
    final controller = ScrollController(initialScrollOffset: 500);

    Widget buildList(String prefix) {
      return ListView.builder(
        controller: controller,
        itemCount: 100,
        itemBuilder: (context, index) => SizedBox(
          height: 50,
          child: Text('$prefix $index'),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: StatusBarScrollToTop(
          controller: controller,
          child: Scaffold(
            body: IndexedStack(
              index: 1,
              children: [
                buildList('Hidden'),
                buildList('Visible'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(controller.positions, hasLength(2));
    tester.simulateStatusBarTap();
    await tester.pumpAndSettle();

    expect(
      controller.positions.map((position) => position.pixels).toList()..sort(),
      [0, 500],
    );

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
