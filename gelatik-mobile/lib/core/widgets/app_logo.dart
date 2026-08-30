import 'package:flutter/material.dart';

/// Centralized official Gelatik identity used by app chrome and auth screens.
class AppLogo extends StatelessWidget {
  final Color textColor;
  final double iconSize;
  final bool showText;

  const AppLogo({
    super.key,
    this.textColor = Colors.white,
    this.iconSize = 34,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        label: 'Logo Gelatik',
        image: true,
        child: Image.asset(
          'assets/images/logo-nobackground&teksgelatik.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
      ),
      if (showText) ...[
        const SizedBox(width: 9),
        Text(
          'Gelatik',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
      ],
    ],
  );
}

/// Formal Lampung identity supplied by the provincial visual system.
class LampungIconBadge extends StatelessWidget {
  final double size;
  final double opacity;

  const LampungIconBadge({super.key, this.size = 96, this.opacity = .16});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Opacity(
      opacity: opacity,
      child: Image.asset(
        'assets/images/icon lampung.png',
        width: size,
        fit: BoxFit.contain,
      ),
    ),
  );
}
