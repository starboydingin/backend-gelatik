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
    final primary = Theme.of(context).colorScheme.primary;
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final logoWidth = isNarrow ? 52.0 : 68.0;
    final titleSize = isNarrow ? 21.0 : 25.0;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: primary,
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
            SizedBox(
              width: logoWidth,
              height: 38,
              child: Image.asset(
                'assets/images/logo-nobackground&teksgelatik.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),
            SizedBox(width: isNarrow ? 8 : 12),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primary,
                fontSize: titleSize,
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
