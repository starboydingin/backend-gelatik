import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// StatusBadge — Pill/Stadium badge dengan warna sesuai status
class StatusBadge extends StatelessWidget {
  final String status;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final normalized = status.trim().toLowerCase();

    Color bgColor;
    Color textColor;

    if (normalized == 'menunggu' || normalized == 'draft' || normalized == 'diajukan') {
      bgColor = isDark ? AppColors.statusInfoDark.withValues(alpha: 0.2) : AppColors.primaryContainerLight;
      textColor = isDark ? AppColors.statusInfoDark : AppColors.statusInfoLight;
    } else if (normalized == 'proses' || normalized == 'diproses') {
      bgColor = isDark ? AppColors.statusWarningDark.withValues(alpha: 0.2) : const Color(0xFFFEF3C7);
      textColor = isDark ? AppColors.statusWarningDark : AppColors.statusWarningLight;
    } else if (normalized == 'selesai' || normalized == 'disetujui') {
      bgColor = isDark ? AppColors.statusSuccessDark.withValues(alpha: 0.2) : const Color(0xFFDCFCE7);
      textColor = isDark ? AppColors.statusSuccessDark : AppColors.statusSuccessLight;
    } else if (normalized == 'ditolak') {
      bgColor = isDark ? AppColors.statusErrorDark.withValues(alpha: 0.2) : const Color(0xFFFEE2E2);
      textColor = isDark ? AppColors.statusErrorDark : AppColors.statusErrorLight;
    } else {
      bgColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
      textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;
    }

    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: bgColor,
        shape: const StadiumBorder(),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
