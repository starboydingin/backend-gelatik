import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Header focused on the current page name; product branding stays in the
/// authentication experience and no longer competes with navigation context.
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
    final primary = Theme.of(context).colorScheme.primary;
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final titleSize = isNarrow ? 17.0 : 19.0;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              tooltip: 'Kembali',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      toolbarHeight: preferredSize.height,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: showBack ? 4 : 20,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: titleSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(height: 3, color: AppColors.colorAccent),
      ),
    );
  }
}
