import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Header ringkas dengan identitas Gelatik untuk layar utama aplikasi.
class GelatikPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const GelatikPageHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final strokeColor = AppColors.cardStroke(context);
    final primaryTeal = AppColors.primaryTeal(context);

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: primaryTeal,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Row(
        children: [
          if (showBack) ...[
            IconButton(
              tooltip: 'Kembali',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
          ] else ...[
            Image.asset(
              'assets/images/logo-gelatik.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.flutter_dash_rounded, color: primaryTeal),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primaryTeal,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(height: 1.5, color: strokeColor),
      ),
    );
  }
}
