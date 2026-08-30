import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BentoBlockTone { white, navy, gold, teal }

/// A single-purpose dashboard surface with one clear visual identity.
class BentoBlock extends StatelessWidget {
  final Widget child;
  final BentoBlockTone tone;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double minHeight;

  const BentoBlock({
    super.key,
    required this.child,
    this.tone = BentoBlockTone.white,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.semanticLabel,
    this.minHeight = 0,
  });

  Color _background() => switch (tone) {
    BentoBlockTone.white => AppColors.colorSurface,
    BentoBlockTone.navy => AppColors.colorPrimary,
    BentoBlockTone.gold => AppColors.colorAccent,
    BentoBlockTone.teal => AppColors.colorSecondary,
  };

  Color _foreground() => switch (tone) {
    BentoBlockTone.white => AppColors.colorTextPrimary,
    BentoBlockTone.gold => AppColors.colorTextPrimary,
    BentoBlockTone.navy || BentoBlockTone.teal => Colors.white,
  };

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: padding,
        child: IconTheme(
          data: IconThemeData(color: _foreground()),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: _foreground()),
            child: child,
          ),
        ),
      ),
    );

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: _background(),
        borderRadius: radius,
        border: tone == BentoBlockTone.white
            ? Border.all(color: AppColors.colorBorder)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, borderRadius: radius, child: content),
      ),
    );

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      container: true,
      child: surface,
    );
  }
}
