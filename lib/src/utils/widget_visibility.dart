import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

bool isWidgetHitTestable(GlobalKey key) {
  final context = key.currentContext;
  final renderObject = context?.findRenderObject();
  if (context == null || renderObject is! RenderBox) {
    return false;
  }

  return isRenderBoxHitTestable(renderObject, context);
}

bool isRenderBoxHitTestable(
  RenderBox renderObject,
  BuildContext context,
) {
  if (!renderObject.attached ||
      !renderObject.hasSize ||
      renderObject.size.isEmpty) {
    return false;
  }

  final center = renderObject.localToGlobal(
    renderObject.size.center(Offset.zero),
  );
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(
    result,
    center,
    View.of(context).viewId,
  );
  return result.path.any((entry) => entry.target == renderObject);
}
