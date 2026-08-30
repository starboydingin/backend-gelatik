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
    final normalized = status.trim().toLowerCase();

    Color bgColor;
    Color textColor;

    if (normalized == 'menunggu' ||
        normalized == 'draft' ||
        normalized == 'diajukan') {
      bgColor = AppColors.colorAccent.withValues(alpha: 0.14);
      textColor = const Color(0xFF9A5B00);
    } else if (normalized == 'proses' || normalized == 'diproses') {
      bgColor = AppColors.colorSecondary.withValues(alpha: 0.12);
      textColor = AppColors.colorSecondary;
    } else if (normalized == 'selesai' || normalized == 'disetujui') {
      bgColor = AppColors.colorSuccess.withValues(alpha: 0.12);
      textColor = AppColors.colorSuccess;
    } else if (normalized == 'ditolak') {
      bgColor = AppColors.colorError.withValues(alpha: 0.1);
      textColor = AppColors.colorError;
    } else {
      bgColor = AppColors.surfaceVariantLight;
      textColor = AppColors.colorTextPrimary;
    }

    return Container(
      padding: padding,
      decoration: ShapeDecoration(color: bgColor, shape: const StadiumBorder()),
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
