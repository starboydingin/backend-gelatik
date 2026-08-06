import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

/// Banner untuk akun yang sedang tidak aktif atau dinonaktifkan admin.
class PendingActivationBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;
  final bool isDialogStyle;

  const PendingActivationBanner({
    super.key,
    this.title = 'Akun Tidak Aktif',
    this.message =
        'Akun Anda sedang tidak aktif atau telah dinonaktifkan. Hubungi administrator jika Anda memerlukan bantuan.',
    this.onDismiss,
    this.isDialogStyle = false,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: PendingActivationBanner(
            title: title ?? 'Akun Tidak Aktif',
            message:
                message ??
                'Akun Anda sedang tidak aktif atau telah dinonaktifkan. Hubungi administrator jika Anda memerlukan bantuan.',
            isDialogStyle: true,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bannerBg = isDark
        ? AppColors.statusWarningDark.withValues(alpha: 0.15)
        : const Color(0xFFFEF3C7);
    final borderCol = isDark
        ? AppColors.accentGoldDark
        : AppColors.accentGoldLight;
    final textCol = isDark ? AppColors.onSurfaceDark : const Color(0xFF92400E);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: borderCol.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: borderCol,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: textCol.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            if (onDismiss != null && !isDialogStyle)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDismiss,
                color: textCol,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        if (isDialogStyle && onDismiss != null) ...[
          const SizedBox(height: 20),
          AppButton(
            text: 'Mengerti',
            onPressed: onDismiss,
            backgroundColor: borderCol,
            textColor: const Color(0xFF1F2937),
          ),
        ],
      ],
    );

    if (isDialogStyle) {
      return content;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol.withValues(alpha: 0.5), width: 1),
      ),
      child: content,
    );
  }
}
