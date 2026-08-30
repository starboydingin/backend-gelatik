import 'package:flutter/material.dart';

enum AppAlertTone { info, success, warning, error }

/// A compact, accessible feedback surface for inline loading and API states.
class AppAlert extends StatelessWidget {
  final String message;
  final AppAlertTone tone;
  final IconData? icon;

  const AppAlert({
    super.key,
    required this.message,
    this.tone = AppAlertTone.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      AppAlertTone.info => scheme.primary,
      AppAlertTone.success => const Color(0xFF10B981),
      AppAlertTone.warning => const Color(0xFFF59E0B),
      AppAlertTone.error => scheme.error,
    };
    final effectiveIcon =
        icon ??
        switch (tone) {
          AppAlertTone.info => Icons.info_outline_rounded,
          AppAlertTone.success => Icons.check_circle_outline_rounded,
          AppAlertTone.warning => Icons.warning_amber_rounded,
          AppAlertTone.error => Icons.error_outline_rounded,
        };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          border: Border.all(color: color.withValues(alpha: .25)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(effectiveIcon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
