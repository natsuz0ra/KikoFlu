import 'package:flutter/material.dart';

import '../utils/widget_visibility.dart';

/// Scrolls an explicitly controlled foreground scroll view to the top when the
/// platform reports a status bar tap.
class StatusBarScrollToTop extends StatefulWidget {
  const StatusBarScrollToTop({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<StatusBarScrollToTop> createState() => _StatusBarScrollToTopState();
}

extension StatusBarScrollToTopExtension on Widget {
  Widget scrollToTopOnStatusBar(ScrollController controller) {
    return StatusBarScrollToTop(
      controller: controller,
      child: this,
    );
  }
}

class _StatusBarScrollToTopState extends State<StatusBarScrollToTop>
    with WidgetsBindingObserver {
  final GlobalKey _visibilityKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void handleStatusBarTap() {
    final controller = widget.controller;
    if (!mounted || !controller.hasClients || !_isForeground()) {
      return;
    }

    for (final position in controller.positions) {
      final notificationContext = position.context.notificationContext;
      final renderObject = notificationContext?.findRenderObject();
      if (!position.hasContentDimensions ||
          position.pixels <= position.minScrollExtent ||
          renderObject is! RenderBox ||
          !isRenderBoxHitTestable(renderObject, notificationContext!)) {
        continue;
      }

      position.animateTo(
        position.minScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _isForeground() {
    final markerContext = _visibilityKey.currentContext;
    final renderObject = markerContext?.findRenderObject();
    if (markerContext == null ||
        renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize ||
        renderObject.size.isEmpty) {
      return false;
    }

    return isRenderBoxHitTestable(renderObject, markerContext);
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
