import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// AppCard — Surface card Neo-Brutalism Teal dengan radius 16px, padding 16-20px, border 1.5px cardStroke TANPA shadow
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double elevation;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.backgroundColor,
    this.elevation = 0.0,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strokeColor = AppColors.cardStroke(context);

    final effectiveBorder = border ??
        Border.all(
          color: strokeColor,
          width: 1.5,
        );

    final cardChild = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: effectiveBorder,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation),
                )
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: cardChild,
        ),
      );
    }

    return cardChild;
  }
}
