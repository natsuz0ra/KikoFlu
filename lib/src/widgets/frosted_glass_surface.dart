import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A lightweight Flutter-drawn frosted surface for HarmonyOS.
///
/// Unlike the Liquid Glass implementation, this widget does not use a
/// platform view or refraction simulation. The blur is clipped to the exact
/// bounds of the control so it remains suitable for floating toolbars and the
/// bottom dock.
class FrostedGlassSurface extends StatelessWidget {
  const FrostedGlassSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    this.intensity = 0.86,
    this.tint,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double intensity;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final strength = intensity.clamp(0.0, 1.0);
    final fillAlpha = highContrast ? 0.98 : 1.0 - 0.92 * strength;
    final blurSigma = highContrast ? 0.0 : 10.0 * strength;
    final baseColor = tint ?? colorScheme.surfaceContainer;
    final edgeColor = Colors.white.withValues(
      alpha: highContrast ? 0.56 : (isDark ? 0.22 : 0.44),
    );
    final highlightAlpha = highContrast ? 0.0 : (isDark ? 0.10 : 0.24);

    final surfaceContent = DecoratedBox(
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: fillAlpha),
        borderRadius: borderRadius,
        border: Border.all(color: edgeColor, width: 0.8),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: highlightAlpha),
                      Colors.white.withValues(alpha: highlightAlpha * 0.24),
                      colorScheme.primary.withValues(
                        alpha: highContrast ? 0.0 : 0.035,
                      ),
                    ],
                    stops: const [0, 0.46, 1],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );

    final surface = blurSigma == 0
        ? surfaceContent
        : BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: surfaceContent,
          );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: highContrast
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.16),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    spreadRadius: -3,
                  ),
                ],
        ),
        child: ClipRRect(borderRadius: borderRadius, child: surface),
      ),
    );
  }
}
