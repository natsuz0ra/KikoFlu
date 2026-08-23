import 'package:flutter/material.dart';

import '../widgets/liquid_glass_layout.dart';

/// SnackBar 工具类，提供统一的提示风格
class SnackBarUtil {
  SnackBarUtil._();

  /// 兼容旧代码中直接构造的 SnackBar，并尽量转成统一样式。
  static void showFromSnackBar(
    BuildContext context,
    SnackBar snackBar, {
    ScaffoldMessengerState? fallbackMessenger,
    void Function(Object error, StackTrace stackTrace)? onError,
    double? dockGap,
  }) {
    try {
      final message = _extractMessage(snackBar.content);
      if (message == null || message.isEmpty) {
        final messenger =
            fallbackMessenger ?? ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          _withDockMargin(
            context,
            snackBar,
            dockExtent: LiquidGlassDockScope.extentOf(context),
            dockGap: dockGap,
          ),
        );
        return;
      }

      final backgroundColor = snackBar.backgroundColor;
      final duration = snackBar.duration;
      final colorScheme = Theme.of(context).colorScheme;

      if (backgroundColor == Colors.red ||
          backgroundColor == colorScheme.error) {
        showError(context, message, duration: duration, dockGap: dockGap);
      } else if (backgroundColor == Colors.green) {
        showSuccess(context, message, duration: duration, dockGap: dockGap);
      } else if (backgroundColor == Colors.orange) {
        showWarning(context, message, duration: duration, dockGap: dockGap);
      } else {
        showInfo(context, message, duration: duration, dockGap: dockGap);
      }
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
  }

  static SnackBar _withDockMargin(
    BuildContext context,
    SnackBar snackBar, {
    required double dockExtent,
    double? dockGap,
  }) {
    if (dockExtent <= 0) return snackBar;

    final margin = snackBar.margin ??
        Theme.of(context).snackBarTheme.insetPadding ??
        const EdgeInsets.fromLTRB(16, 5, 16, 8);
    var resolvedMargin = margin.resolve(Directionality.of(context));
    if (snackBar.width != null) {
      final horizontal = ((MediaQuery.sizeOf(context).width - snackBar.width!) / 2)
          .clamp(0.0, double.infinity)
          .toDouble();
      resolvedMargin = EdgeInsets.fromLTRB(
        horizontal,
        resolvedMargin.top,
        horizontal,
        resolvedMargin.bottom,
      );
    }

    return SnackBar(
      key: snackBar.key,
      content: snackBar.content,
      backgroundColor: snackBar.backgroundColor,
      elevation: snackBar.elevation,
      margin: resolvedMargin.copyWith(
        bottom: dockGap == null
            ? resolvedMargin.bottom + dockExtent
            : dockExtent + dockGap,
      ),
      padding: snackBar.padding,
      shape: snackBar.shape,
      hitTestBehavior: snackBar.hitTestBehavior,
      behavior: SnackBarBehavior.floating,
      action: snackBar.action,
      actionOverflowThreshold: snackBar.actionOverflowThreshold,
      showCloseIcon: snackBar.showCloseIcon,
      closeIconColor: snackBar.closeIconColor,
      duration: snackBar.duration,
      persist: snackBar.persist,
      animation: snackBar.animation,
      onVisible: snackBar.onVisible,
      dismissDirection: snackBar.dismissDirection,
      clipBehavior: snackBar.clipBehavior,
    );
  }

  static void _show(
    BuildContext context,
    SnackBar snackBar, {
    double? dockGap,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      _withDockMargin(
        context,
        snackBar,
        dockExtent: LiquidGlassDockScope.extentOf(context),
        dockGap: dockGap,
      ),
    );
  }

  static String? _extractMessage(Widget content) {
    if (content is Text) {
      return content.data;
    }

    if (content is Row) {
      for (final child in content.children) {
        if (child is Text) {
          return child.data;
        }

        if (child is Expanded && child.child is Text) {
          return (child.child as Text).data;
        }
      }
    }

    return null;
  }

  /// 显示成功提示
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    double? dockGap,
  }) {
    _show(
      context,
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: duration,
      ),
      dockGap: dockGap,
    );
  }

  /// 显示错误提示
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    double? dockGap,
  }) {
    _show(
      context,
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
      ),
      dockGap: dockGap,
    );
  }

  /// 显示警告提示
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    double? dockGap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    // 使用 tertiary 或 secondary 作为警告色
    final warningColor = colorScheme.tertiary;
    final onWarningColor = colorScheme.onTertiary;

    _show(
      context,
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: onWarningColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: onWarningColor,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: warningColor,
        duration: duration,
      ),
      dockGap: dockGap,
    );
  }

  /// 显示信息提示
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    double? dockGap,
  }) {
    _show(
      context,
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        duration: duration,
      ),
      dockGap: dockGap,
    );
  }

  /// 显示加载提示
  static void showLoading(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 30),
  }) {
    _show(
      context,
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        duration: duration,
      ),
    );
  }

  /// 隐藏当前显示的 SnackBar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// 清除所有 SnackBar
  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
