import 'package:flutter/material.dart';

import '../utils/widget_visibility.dart';

class NavigationTabReselectController extends ChangeNotifier {
  void reselect() => notifyListeners();
}

extension NavigationTabReselectExtension on Widget {
  Widget onNavigationTabReselect({
    required NavigationTabReselectController controller,
    required VoidCallback onReselect,
  }) {
    return NavigationTabReselectListener(
      controller: controller,
      onReselect: onReselect,
      child: this,
    );
  }
}

class NavigationTabReselectListener extends StatefulWidget {
  const NavigationTabReselectListener({
    super.key,
    required this.controller,
    required this.onReselect,
    required this.child,
  });

  final NavigationTabReselectController controller;
  final VoidCallback onReselect;
  final Widget child;

  @override
  State<NavigationTabReselectListener> createState() =>
      _NavigationTabReselectListenerState();
}

class _NavigationTabReselectListenerState
    extends State<NavigationTabReselectListener> {
  final GlobalKey _visibilityKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleReselect);
  }

  @override
  void didUpdateWidget(covariant NavigationTabReselectListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleReselect);
    widget.controller.addListener(_handleReselect);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleReselect);
    super.dispose();
  }

  void _handleReselect() {
    if (mounted && isWidgetHitTestable(_visibilityKey)) {
      widget.onReselect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MetaData(
      key: _visibilityKey,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
