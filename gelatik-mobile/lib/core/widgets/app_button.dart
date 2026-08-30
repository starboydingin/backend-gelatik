import 'package:flutter/material.dart';

enum AppButtonVariant { filled, outlined }

/// Shared mobile action: rounded enough for touch, never a pill by default.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool allowTextWrap;
  final bool showBorder;

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
    this.allowTextWrap = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBgColor =
        backgroundColor ??
        (variant == AppButtonVariant.filled
            ? theme.colorScheme.secondary
            : Colors.transparent);
    final effectiveTextColor =
        textColor ??
        (variant == AppButtonVariant.filled
            ? theme.colorScheme.onSecondary
            : theme.colorScheme.primary);

    final textWidget = Text(
      text,
      textAlign: TextAlign.center,
      softWrap: allowTextWrap,
      maxLines: allowTextWrap ? 2 : 1,
      overflow: allowTextWrap ? null : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: effectiveTextColor,
      ),
    );

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
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: effectiveTextColor),
                const SizedBox(width: 8),
              ],
              Flexible(child: textWidget),
            ],
          );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: effectiveBgColor,
      foregroundColor: effectiveTextColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: variant == AppButtonVariant.outlined && showBorder
            ? BorderSide(color: effectiveTextColor, width: 1.25)
            : BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      minimumSize: isFullWidth ? const Size.fromHeight(48) : null,
    );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: childContent,
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
