import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Main navigation defined by DESIGN.md. Admin is a role-aware fifth tab.
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final items = [
      const _NavItem(label: 'Beranda', icon: Icons.home_outlined),
      const _NavItem(label: 'Layanan', icon: Icons.grid_view_outlined),
      const _NavItem(label: 'Notifikasi', icon: Icons.notifications_outlined),
      const _NavItem(label: 'Profil', icon: Icons.person_outline_rounded),
      if (isAdmin)
        const _NavItem(
          label: 'Admin',
          icon: Icons.admin_panel_settings_rounded,
        ),
    ];

    return SizedBox(
      height: 74 + bottomInset,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.colorPrimary,
          border: Border(
            top: const BorderSide(color: AppColors.colorPrimaryDark),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;
                    final color = isSelected
                        ? AppColors.colorAccent
                        : AppColors.onPrimaryLight.withValues(alpha: .78);

                    return Expanded(
                      child: InkWell(
                        onTap: () => onTap(index),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
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
                              const SizedBox(height: 3),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: isSelected ? 22 : 0,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.colorAccent,
                                  borderRadius: BorderRadius.circular(3),
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
