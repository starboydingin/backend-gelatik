import 'package:flutter/material.dart';

enum AppButtonVariant { filled, outlined }

/// AppButton — Reusable button with stadium/24px rounded border
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBgColor = backgroundColor ??
        (variant == AppButtonVariant.filled
            ? theme.colorScheme.primary
            : Colors.transparent);
    final effectiveTextColor = textColor ??
        (variant == AppButtonVariant.filled
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.primary);

    final Widget childContent = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: effectiveTextColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: effectiveTextColor,
                ),
              ),
            ],
          );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: effectiveBgColor,
      foregroundColor: effectiveTextColor,
      elevation: variant == AppButtonVariant.filled ? 1 : 0,
      shape: StadiumBorder(
        side: variant == AppButtonVariant.outlined
            ? BorderSide(color: effectiveTextColor, width: 1.5)
            : BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      minimumSize: isFullWidth ? const Size.fromHeight(48) : null,
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: childContent,
    );
  }
}
