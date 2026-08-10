import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom navigation Gelatik: flat, mudah dibaca, dan sama pada mobile/desktop.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final items = [
      const _NavItem(label: 'Beranda', icon: Icons.home_rounded),
      const _NavItem(label: 'Ajukan', icon: Icons.add_circle_outline_rounded),
      const _NavItem(label: 'Profil', icon: Icons.person_outline_rounded),
      if (isAdmin)
        const _NavItem(
          label: 'Admin',
          icon: Icons.admin_panel_settings_rounded,
        ),
    ];

    return SizedBox(
      height: 88 + bottomInset,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: AppColors.cardStroke(context), width: 1.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;
                    final color = isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant;

                    return Expanded(
                      child: InkWell(
                        onTap: () => onTap(index),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.icon, color: color, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: color,
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(top: 3),
                                width: isSelected ? 4 : 0,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem({required this.label, required this.icon});
}
